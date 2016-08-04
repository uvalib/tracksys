class MasterFile < ActiveRecord::Base

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :component, :counter_cache => true
   belongs_to :indexing_scenario, :counter_cache => true
   belongs_to :unit
   belongs_to :use_right, :counter_cache => true
   belongs_to :item

   has_and_belongs_to_many :legacy_identifiers

   has_many :job_statuses, :as => :originator, :dependent => :destroy

   has_one :image_tech_meta, :dependent => :destroy
   has_one :order, :through => :unit
   has_one :bibl, :through => :unit
   has_one :customer, :through => :order
   has_one :academic_status, :through => :customer
   has_one :department, :through => :customer
   has_one :agency, :through => :order

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
   before_save do
      # default right statement to not Evaluated
      if self.use_right.blank?
        cne = UseRight.find_by(name: "Copyright Not Evaluated")
        self.use_right = cne
      end
   end
   after_create do
      update_attribute(:pid, "tsm:#{self.id}")
   end

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :in_digital_library, ->{ where("master_files.date_dl_ingest is not null").order("master_files.date_dl_ingest ASC") }
   scope :not_in_digital_library, ->{ where("master_files.date_dl_ingest is null") }

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

   def iiif_path(pid)
      pid_parts = pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/../) # break up into 2 digit sections, but this leaves off last char if odd
      parts << base.last if parts.length * 2 !=  base.length
      pid_dirs = parts.join("/")
      jp2k_filename = "#{base}.jp2"
      jp2k_path = File.join(Settings.iiif_mount, pid_parts[0], pid_dirs)
      jp2k_path = File.join(jp2k_path, jp2k_filename)
      return jp2k_path
   end

   def link_to_static_thumbnail(large=false)
      iiif_url = URI.parse("#{Settings.iiif_url}/#{self.pid}/full/!125,125/0/default.jpg")
      iiif_url = URI.parse("#{Settings.iiif_url}/#{self.pid}/full/,640/0/default.jpg") if large == true
      test_path = iiif_path(self.pid)
      if File.exists?(test_path) == false
         if Settings.create_missing_kp2k == "true"
            Rails.logger.info "CREATE JP2 for #{self.pid}"
            unit_id = self.unit.id.to_s
            src = File.join(Settings.archive_mount, unit_id.rjust(9, "0") )
            PublishToIiif.exec({source: "#{src}/#{self.filename}", master_file_id: self.id})
         else
            thumbnail_name = self.filename.gsub(/(tif|jp2)/, 'jpg')
            unit_dir = "%09d" % self.unit_id
            min_range = self.unit_id / 1000 * 1000    # round unit to thousands
            max_range = min_range + 999               # add 999 for a 1000 span range, like 33000-33999
            range_sub_dir = "#{min_range}-#{max_range}"
            return "/metadata/#{range_sub_dir}/#{unit_dir}/Thumbnails_(#{unit_dir})/#{thumbnail_name}"
         end
      end

      return iiif_url.to_s
   end

   # alias_attributes as CYA for legacy migration.
   alias_attribute :name_num, :title
   alias_attribute :staff_notes, :description

   def get_from_stornext(computing_id)
      CopyArchivedFilesToProduction.exec( {:unit => self.unit, :master_file_filename => self.filename, :computing_id => computing_id })
   end

   def increment_counter_caches
      # Conditionalize Bibl increment because it is not required.
      # Bibl.increment_counter('master_files_count', self.bibl.id) if self.bibl
      Customer.increment_counter('master_files_count', self.customer.id)
   end

   def decrement_counter_caches
      # Conditionalize Bibl decrement because it is not required.
      # Bibl.decrement_counter('master_files_count', self.bibl.id) if self.bibl
      Customer.decrement_counter('master_files_count', self.customer.id)
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

   def legacy_identifier_links
      return ""  if self.legacy_identifiers.empty?
      out = ""
      self.legacy_identifiers.each do |li|
         out << "<div><a href='/admin/legacy_identifiers/#{li.id}'>#{li.description} (#{li.legacy_identifier})</a></div>"
      end
      return out
   end
end

# == Schema Information
#
# Table name: master_files
#
#  id                     :integer          not null, primary key
#  unit_id                :integer          default(0), not null
#  component_id           :integer
#  tech_meta_type         :string(255)
#  filename               :string(255)
#  filesize               :integer
#  title                  :string(255)
#  date_archived          :datetime
#  description            :string(255)
#  pid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  transcription_text     :text(65535)
#  desc_metadata          :text(65535)
#  discoverability        :boolean          default(FALSE)
#  md5                    :string(255)
#  indexing_scenario_id   :integer
#  use_right_id           :integer
#  date_dl_ingest         :datetime
#  date_dl_update         :datetime
#  dpla                   :boolean          default(FALSE)
#  creator_death_date     :string(255)
#  creation_date          :string(255)
#  primary_author         :string(255)
#
