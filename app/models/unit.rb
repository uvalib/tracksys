class Unit < ActiveRecord::Base
   include Pidable
   require 'rqrcode'

   UNIT_STATUSES = %w[approved canceled condition copyright unapproved]

   # The request form requires having data stored temporarily to the unit model and then concatenated into special instructions.  Those fields are:
   attr_accessor :request_call_number, :request_copy_number, :request_volume_number, :request_issue_number, :request_location, :request_title, :request_author, :request_year, :request_description, :request_pages_to_digitize


   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :availability_policy, :counter_cache => true
   belongs_to :bibl, :counter_cache => true
   belongs_to :heard_about_resource, :counter_cache => true
   belongs_to :intended_use, :counter_cache => true
   belongs_to :indexing_scenario, :counter_cache => true
   belongs_to :order, :counter_cache => true, :inverse_of => :units
   belongs_to :use_right, :counter_cache => true

   has_many :master_files
   has_many :components, :through => :master_files#, :uniq => true
   has_many :job_statuses, :as => :originator, :dependent => :destroy

   has_one :agency, :through => :order
   has_one :customer, :through => :order

   delegate :call_number, :title, :catalog_key, :barcode, :pid, :exemplar,
   :to => :bibl, :allow_nil => true, :prefix => true
   delegate :id, :full_name,
   :to => :customer, :allow_nil => true, :prefix => true
   delegate :date_due,
   :to => :order, :allow_nil => true, :prefix => true
   delegate :deliverable_format, :deliverable_resolution, :deliverable_resolution_unit,
   :to => :intended_use, :allow_nil => true, :prefix => true

   belongs_to :index_destination, :counter_cache => true
   has_and_belongs_to_many :legacy_identifiers

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :in_repo, ->{where("date_dl_deliverables_ready IS NOT NULL").order("date_dl_deliverables_ready DESC") }
   scope :ready_for_repo, ->{where(:include_in_dl => true).where("`units`.availability_policy_id IS NOT NULL").where(:date_queued_for_ingest => nil).where("date_archived is not null") }
   scope :awaiting_copyright_approval, ->{where(:unit_status => 'copyright') }
   scope :awaiting_condition_approval, ->{where(:unit_status => 'condition') }
   scope :approved, ->{where(:unit_status => 'approved') }
   scope :unapproved, ->{where(:unit_status => 'unapproved') }
   scope :canceled, ->{where(:unit_status => 'canceled') }
   scope :overdue_materials, ->{where("date_materials_received IS NOT NULL AND date_archived IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"') }
   scope :checkedout_materials, ->{where("date_materials_received IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"') }
   scope :uncompleted_units_of_partially_completed_orders, ->{includes(:order).where(:unit_status => 'approved', :date_archived => nil).where('intended_use_id != 110').where('orders.date_finalization_begun is not null') }


   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------

   # validates :order_id, :numericality => { :greater_than => 1 }
   validates_presence_of :order
   validates :patron_source_url, :format => {:with => URI::regexp(['http','https'])}, :allow_blank => true
   validates :availability_policy, :presence => {
      :if => 'self.availability_policy_id',
      :message => "association with this AvailabilityPolicy is no longer valid because it no longer exists."
   }
   validates :bibl, :presence => {
      :if => 'self.bibl_id',
      :message => "association with this Bibl is no longer valid because it no longer exists."
   }
   validates :heard_about_resource, :presence => {
      :if => 'self.heard_about_resource_id',
      :message => "association with this HeardAboutResource is no longer valid because it no longer exists."
   }
   validates :intended_use, :presence => {
      :message => "must be selected."
   }
   validates :indexing_scenario, :presence => {
      :if => 'self.indexing_scenario_id',
      :message => "association with this IndexingScenario is no longer valid because it no longer exists."
   }
   validates :order, :presence => {
      :if => 'self.order_id',
      :message => "association with this Order is no longer valid because it no longer exists."
   }
   validates :use_right, :presence => {
      :if => 'self.use_right_id',
      :message => "association with this UseRight is no longer valid because it no longer exists."
   }

   # comment this out for the time being
   # validates :unit_status, :inclusion => { :in => UNIT_STATUSES, :message => 'must be one of these values: ' + UNIT_STATUSES.join(", ")}

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_save do
      # boolean fields cannot be NULL at database level
      self.exclude_from_dl = 0 if self.exclude_from_dl.nil?
      self.include_in_dl = 0 if self.include_in_dl.nil?
      self.master_file_discoverability = 0 if self.master_file_discoverability.nil?
      self.order_id = 0 if self.order_id.nil?
      self.remove_watermark = 0 if self.remove_watermark.nil?
      self.unit_status = "unapproved" if self.unit_status.nil? || self.unit_status.empty?
   end
   after_update :check_order_status, :if => :unit_status_changed?

   #------------------------------------------------------------------
   # aliases
   #------------------------------------------------------------------
   # Necessary for Active Admin to poplulate pulldown menu
   alias_attribute :name, :id

   #------------------------------------------------------------------
   # public class methods
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   def approved?
      if self.unit_status == "approved"
         return true
      else
         return false
      end
   end

   def canceled?
      if self.unit_status == "canceled"
         return true
      else
         return false
      end
   end

   def in_dl?
      return self.date_dl_deliverables_ready?
   end

   def ready_for_repo?
      if self.include_in_dl == true and not self.availability_policy_id.nil? and self.date_queued_for_ingest.nil? and not self.date_archived.nil?
         return true
      else
         return false
      end
   end

   def check_order_status
      if self.order.ready_to_approve?
         self.order.order_status = 'approved'
         self.order.date_order_approved = Time.now
         self.order.save!
      end
   end

   # Within the scope of a Unit's order, return the Unit which follows
   # or precedes the current Unit sequentially.
   def next
      units_sorted = self.order.units.sort_by {|unit| unit.id}
      if units_sorted.find_index(self) < units_sorted.length
         return units_sorted[units_sorted.find_index(self)+1]
      else
         return nil
      end
   end

   def previous
      units_sorted = self.order.units.sort_by {|unit| unit.id}
      if units_sorted.find_index(self) > 0
         return units_sorted[units_sorted.find_index(self)-1]
      else
         return nil
      end
   end

   def check_unit_delivery_mode
      CheckUnitDeliveryMode.exec( {:unit_id => self.id})
   end

   def get_from_stornext(computing_id)
      CopyArchivedFilesToProduction.exec( {:workflow_type => 'patron', :unit_id => self.id, :computing_id => computing_id })
   end

   def import_unit_iview_xml
      unit_dir = "%09d" % self.id
      ImportUnitIviewXML.exec( {:unit_id => self.id, :path => "#{IN_PROCESS_DIR}/#{unit_dir}/#{unit_dir}.xml"})
   end

   def qa_filesystem_and_iview_xml
      logger.tagged("MS3UF") { logger.debug "model method Unit#qa_filesystem_and_iview_xml called on #{self.id}" }
      QaFilesystemAndIviewXml.exec( {:unit_id => self.id} )
   end

   def qa_unit_data
      QaUnitData.exec( {:unit_id => self.id})
   end

   def queue_unit_deliverables
      @unit_dir = "%09d" % self.id
      QueueUnitDeliverables.exec( {:unit_id => self.id, :mode => 'patron', :source => File.join(PROCESS_DELIVERABLES_DIR, 'patron', @unit_dir)})
   end

   def send_unit_to_archive
      SendUnitToArchive.exec( {:unit_id => self.id, :internal_dir => 'yes', :source_dir => "#{IN_PROCESS_DIR}"})
   end

   def start_ingest_from_archive
      StartIngestFromArchive.exec( {:unit_id => self.id, :order_id => self.order_id })
   end

   def copy_metadata_to_metadata_directory
      unit_dir = "%09d" % self.id
      unit_path = File.join(IN_PROCESS_DIR, unit_dir)
      CopyMetadataToMetadataDirectory.exec( {:unit_id => self.id, :unit_path => unit_path})
   end

   # End processors

   def qr
      code = RQRCode::QRCode.new("#{TRACKSYS_URL}/admin/unit/checkin/#{self.id}", :size => 7)
      return code
   end

   # utility method to present consistent Fedora object structure within a unit
   # Ordinarily, MasterFiles without transcription text do not generate a 'transcription'
   # datastream upon ingest, but this method will add blank transcription fields to
   # MasterFile objects and update their Repository counterparts as needed
   def fill_in_missing_transcriptions
      text=" \n"
      empty_items=self.master_files.where(:transcription_text => nil)
      if empty_items.count > 0
         empty_items.each do |item|
            item.transcription_text=text unless item.transcription_text
            item.save!
            item.reload
            if item.exists_in_repo?
               Fedora.add_or_update_datastream(item.transcription_text, item.pid,
               'transcription', 'Transcription', :contentType => 'text/plain',
               :mimeType => 'text/plain', :controlGroup => 'M')
            end
         end
      end
   end

end
# == Schema Information
#
# Table name: units
#
#  id                             :integer(4)      not null, primary key
#  order_id                       :integer(4)      default(0), not null
#  bibl_id                        :integer(4)
#  heard_about_resource_id        :integer(4)
#  unit_status                    :string(255)
#  date_materials_received        :datetime
#  date_materials_returned        :datetime
#  unit_extent_estimated          :integer(4)
#  unit_extent_actual             :integer(4)
#  patron_source_url              :text
#  special_instructions           :text
#  created_at                     :datetime
#  updated_at                     :datetime
#  intended_use_id                :integer(4)
#  exclude_from_dl                :boolean(1)      default(FALSE), not null
#  staff_notes                    :text
#  use_right_id                   :integer(4)
#  date_queued_for_ingest         :datetime
#  date_archived                  :datetime
#  date_patron_deliverables_ready :datetime
#  include_in_dl                  :boolean(1)      default(FALSE)
#  date_dl_deliverables_ready     :datetime
#  remove_watermark               :boolean(1)      default(FALSE)
#  master_file_discoverability    :boolean(1)      default(FALSE)
#  indexing_scenario_id           :integer(4)
#  checked_out                    :boolean(1)      default(FALSE)
#  availability_policy_id         :integer(4)
#  master_files_count             :integer(4)      default(0)
#  index_destination_id           :integer(4)
#
