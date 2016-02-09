class MasterFile < ActiveRecord::Base
   include Pidable

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :availability_policy, :counter_cache => true
   belongs_to :component, :counter_cache => true
   belongs_to :indexing_scenario, :counter_cache => true
   belongs_to :unit, :counter_cache => true
   belongs_to :use_right, :counter_cache => true

   has_and_belongs_to_many :legacy_identifiers

   has_many :automation_messages, :as => :messagable, :dependent => :destroy

   has_one :image_tech_meta, :dependent => :destroy
   has_one :order, :through => :unit
   has_one :bibl, :through => :unit
   has_one :customer, :through => :order
   has_one :academic_status, :through => :customer
   has_one :department, :through => :customer
   has_one :agency, :through => :order
   has_one :heard_about_resource, :through => :unit
   has_one :heard_about_service, :through => :customer

   #------------------------------------------------------------------
   # delegation
   #------------------------------------------------------------------
   delegate :call_number, :title, :catalog_key, :barcode, :id, :creator_name, :year,
   :to => :bibl, :allow_nil => true, :prefix => true

   delegate :include_in_dl, :exclude_in_dl, :date_archived, :date_queued_for_ingest, :date_dl_deliverables_ready,
   :to => :unit, :allow_nil => true, :prefix => true

   delegate :date_due, :date_order_approved, :date_request_submitted, :date_customer_notified, :id,
   :to => :order, :allow_nil => true, :prefix => true

   delegate :full_name, :id, :last_name, :first_name,
   :to => :customer, :allow_nil => true, :prefix => true

   delegate :name,
   :to => :academic_status, :allow_nil => true, :prefix => true

   delegate :name,
   :to => :agency, :allow_nil => true, :prefix => true

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :filename, :unit_id, :filesize, :presence => true
   validates :availability_policy, :presence => {
      :if => 'self.availability_policy_id',
      :message => "association with this AvailabilityPolicy is no longer valid because it no longer exists."
   }
   validates :component, :presence => {
      :if => 'self.component_id',
      :message => "association with this Component is no longer valid because it no longer exists."
   }
   validates :indexing_scenario, :presence => {
      :if => 'self.indexing_scenario_id',
      :message => "association with this IndexingScenario is no longer valid because it no longer exists."
   }
   validates :unit, :presence => {
      :message => "association with this Unit is no longer valid because it no longer exists."
   }
   validates :use_right, :presence => {
      :if => 'self.use_right_id',
      :message => "association with this Use is no longer valid because it no longer exists."
   }

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   after_create :increment_counter_caches
   after_destroy :decrement_counter_caches

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :in_digital_library, where("master_files.date_dl_ingest is not null").order("master_files.date_dl_ingest ASC")
   scope :not_in_digital_library, where("master_files.date_dl_ingest is null")
   # default_scope :include => [:availability_policy, :component, :indexing_scenario, :unit, :use_right]

   #------------------------------------------------------------------
   # public class methods
   #------------------------------------------------------------------
   def in_dl?
      return self.date_dl_ingest?
   end

   # Within the scope of a current MasterFile's Unit, return the MasterFile object
   # that preceedes self.  Used to create links and relationships between objects.
   def previous
      master_files_sorted = self.sorted_set
      if master_files_sorted.find_index(self) > 0
         return master_files_sorted[master_files_sorted.find_index(self)-1]
      else
         return nil
      end
   end

   def sorted_set
      master_files_sorted = self.unit.master_files.sort_by {|mf| mf.filename}
   end

   def link_to_dl_thumbnail
      return "http://fedoraproxy.lib.virginia.edu/fedora/get/#{self.pid}/djatoka:jp2SDef/getRegion?scale=125"
   end

   def link_to_dl_page_turner
      return "#{VIRGO_URL}/#{self.bibl.pid}/view?&page=#{self.pid}"
   end

   def path_to_archved_version
      return "#{ARCHIVE_DIR}/" + "#{'%09d' % self.unit_id}/" + "#{self.filename}"
   end

   def link_to_static_thumbnail
      thumbnail_name = self.filename.gsub(/(tif|jp2)/, 'jpg')
      unit_dir = "%09d" % self.unit_id
      begin
         # Get the contents of /digiserv-production/metadata and exclude directories that don't begin with and end with a number.  Hopefully this
         # will eliminate other directories that are of non-Tracksys managed content.
         metadata_dir_contents = Dir.entries(PRODUCTION_METADATA_DIR).delete_if {|x| x == '.' or x == '..' or not /^[0-9](.*)[0-9]$/ =~ x}
         metadata_dir_contents.each {|dir|
            range = dir.split('-')
            if self.unit_id.to_i.between?(range.first.to_i, range.last.to_i)
               @range_dir = dir
            end
         }
      rescue
         @range_dir="fixme"
      end
      return "/metadata/#{@range_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})/#{thumbnail_name}"
   end

   def mime_type
      "image/tiff"
   end

   # alias_attributes as CYA for legacy migration.
   alias_attribute :name_num, :title
   alias_attribute :staff_notes, :description

   def get_from_stornext(computing_id)
      CopyArchivedFilesToProduction.exec( {:workflow_type => 'patron', :unit_id => self.unit_id, :master_file_filename => self.filename, :computing_id => computing_id })
   end

   def update_thumb_and_tech
      if self.image_tech_meta
         self.image_tech_meta.destroy
      end
      sleep(0.1)

      message = { :master_file_id => self.id, :source => self.path_to_archved_version}
      CreateImageTechnicalMetadataAndThumbnail.exec( message )
   end

   def increment_counter_caches
      # Conditionalize Bibl increment because it is not required.
      # Bibl.increment_counter('master_files_count', self.bibl.id) if self.bibl
      Customer.increment_counter('master_files_count', self.customer.id)
      Order.increment_counter('master_files_count', self.order.id)
   end

   def decrement_counter_caches
      # Conditionalize Bibl decrement because it is not required.
      # Bibl.decrement_counter('master_files_count', self.bibl.id) if self.bibl
      Customer.decrement_counter('master_files_count', self.customer.id)
      Order.decrement_counter('master_files_count', self.order.id)
   end

   # Within the scope of a current MasterFile's Unit, return the MasterFile object
   # that follows self.  Used to create links and relationships between objects.
   def next
      master_files_sorted = self.sorted_set
      if master_files_sorted.find_index(self) < master_files_sorted.length
         return master_files_sorted[master_files_sorted.find_index(self)+1]
      else
         return nil
      end
   end
end
# == Schema Information
#
# Table name: master_files
#
#  id                        :integer(4)      not null, primary key
#  unit_id                   :integer(4)      default(0), not null
#  component_id              :integer(4)
#  tech_meta_type            :string(255)
#  filename                  :string(255)
#  filesize                  :integer(4)
#  title                     :string(255)
#  date_archived             :datetime
#  description               :string(255)
#  pid                       :string(255)
#  created_at                :datetime
#  updated_at                :datetime
#  transcription_text        :text
#  desc_metadata             :text
#  rels_ext                  :text
#  solr                      :text(2147483647
#  dc                        :text
#  rels_int                  :text
#  discoverability           :boolean(1)      default(FALSE)
#  md5                       :string(255)
#  indexing_scenario_id      :integer(4)
#  availability_policy_id    :integer(4)
#  automation_messages_count :integer(4)      default(0)
#  use_right_id              :integer(4)
#  date_dl_ingest            :datetime
#  date_dl_update            :datetime
#  dpla                      :boolean(1)      default(FALSE)
#  type                      :string(255)
#  creator_death_date        :string(255)
#  creation_date             :string(255)
#  primary_author            :string(255)
#
