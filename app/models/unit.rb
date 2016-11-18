class Unit < ActiveRecord::Base

   UNIT_STATUSES = %w[approved canceled condition copyright unapproved]

   # The request form requires having data stored temporarily to the unit model and
   # then concatenated into special instructions.  Those fields are:
   attr_accessor :request_call_number, :request_copy_number, :request_volume_number,
      :request_issue_number, :request_location, :request_title, :request_author, :request_year,
      :request_description, :request_pages_to_digitize

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :metadata, :counter_cache => true
   belongs_to :intended_use, :counter_cache => true
   belongs_to :order, :counter_cache => true, :inverse_of => :units

   has_many :master_files
   has_many :components, :through => :master_files#, :uniq => true
   has_many :job_statuses, :as => :originator, :dependent => :destroy
   has_many :attachments, :dependent=>:destroy

   has_one :agency, :through => :order
   has_one :customer, :through => :order
   has_one :department, :through => :order

   delegate :title, :to=>:metadata, :allow_nil => true, :prefix => true
   delegate :date_due, :to => :order, :allow_nil => true, :prefix => true
   delegate :deliverable_format, :deliverable_resolution, :deliverable_resolution_unit,
      :to => :intended_use, :allow_nil => true, :prefix => true

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :in_repo, ->{where("date_dl_deliverables_ready IS NOT NULL").order("date_dl_deliverables_ready DESC") }
   scope :ready_for_repo, ->{joins(:metadata).where("metadata.availability_policy_id is not null").where(:include_in_dl => true).where(:date_queued_for_ingest => nil).where("date_archived is not null") }
   scope :awaiting_copyright_approval, ->{where(:unit_status => 'copyright') }
   scope :awaiting_condition_approval, ->{where(:unit_status => 'condition') }
   scope :approved, ->{where(:unit_status => 'approved') }
   scope :unapproved, ->{where(:unit_status => 'unapproved') }
   scope :canceled, ->{where(:unit_status => 'canceled') }
   scope :overdue_materials, ->{where("date_materials_received IS NOT NULL AND date_archived IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"') }
   scope :checkedout_materials, ->{where("date_materials_received IS NOT NULL AND date_materials_returned IS NULL").where('date_materials_received >= "2012-03-01"') }
   scope :uncompleted_units_of_partially_completed_orders, ->{includes(:order).where(:unit_status => 'approved', :date_archived => nil).where('intended_use_id != 110').where('orders.date_finalization_begun is not null').references(:order) }


   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates_presence_of :order
   validates :patron_source_url, :format => {:with => URI::regexp(['http','https'])}, :allow_blank => true
   validates :intended_use, :presence => {
      :message => "must be selected."
   }
   validates :order, :presence => {
      :if => 'self.order_id',
      :message => "association with this Order is no longer valid because it no longer exists."
   }

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_save do
      # boolean fields cannot be NULL at database level
      self.include_in_dl = 0 if self.include_in_dl.nil?
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

   def has_xml_masterfiles?
      self.master_files.each do |mf|
         next if mf.metadata == self.metadata
         return true if mf.metadata.type == "XmlMetadata"
      end
      return false
   end

   def ready_for_repo?
      return false if self.include_in_dl == false
      return false if self.metadata.nil?
      return false if self.metadata.availability_policy_id.nil?
      return true if self.date_queued_for_ingest.nil? and not self.date_archived.nil?
      return false
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

   def patron_deliverables_available?
      return false if self.date_patron_deliverables_ready.nil?
      assemble_dir = File.join(ASSEMBLE_DELIVERY_DIR, "order_#{self.order.id}", self.id.to_s)
      return false if !Dir.exist? assemble_dir
      return Dir["#{assemble_dir}/*"].length >= self.master_files.count
   end

   def create_patron_zip
      CreateUnitZip.exec({unit: self, replace: true})
   end

   def check_unit_delivery_mode
      CheckUnitDeliveryMode.exec( {:unit => self} )
   end

   def get_from_stornext(computing_id)
      CopyArchivedFilesToProduction.exec( {:unit => self, :computing_id => computing_id })
   end

   def import_unit_iview_xml
      unit_dir = "%09d" % self.id
      ImportUnitIviewXML.exec( {:unit => self, :path => "#{IN_PROCESS_DIR}/#{unit_dir}/#{unit_dir}.xml"})
   end

   def qa_filesystem_and_iview_xml
      QaFilesystemAndIviewXml.exec( {:unit => self} )
   end

   def qa_unit_data
      QaUnitData.exec( {:unit => self})
   end

   def send_unit_to_archive
      SendUnitToArchive.exec( {:unit => self, :internal_dir => true, :source_dir => "#{IN_PROCESS_DIR}"})
   end
end

# == Schema Information
#
# Table name: units
#
#  id                             :integer          not null, primary key
#  order_id                       :integer          default(0), not null
#  metadata_id                    :integer
#  unit_status                    :string(255)
#  date_materials_received        :datetime
#  date_materials_returned        :datetime
#  unit_extent_estimated          :integer
#  unit_extent_actual             :integer
#  patron_source_url              :text(65535)
#  special_instructions           :text(65535)
#  created_at                     :datetime
#  updated_at                     :datetime
#  intended_use_id                :integer
#  staff_notes                    :text(65535)
#  date_queued_for_ingest         :datetime
#  date_archived                  :datetime
#  date_patron_deliverables_ready :datetime
#  include_in_dl                  :boolean          default(FALSE)
#  date_dl_deliverables_ready     :datetime
#  remove_watermark               :boolean          default(FALSE)
#  checked_out                    :boolean          default(FALSE)
#  master_files_count             :integer          default(0)
#  complete_scan                  :boolean          default(FALSE)
#
