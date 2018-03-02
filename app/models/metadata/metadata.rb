class Metadata < ApplicationRecord

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :availability_policy, counter_cache: true, optional: true
   belongs_to :use_right, counter_cache: true

   belongs_to :ocr_hint, optional: true
   belongs_to :genre, optional: true
   belongs_to :resource_type, optional: true
   belongs_to :preservation_tier, optional: true

   has_many :master_files
   has_many :units
   has_many :orders, :through => :units
   has_many :job_statuses, :as => :originator, :dependent => :destroy

   has_many :agencies, :through => :orders
   has_many :customers, :through => :orders
   has_many :checkouts

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :approved, ->{ where(:is_approved => true) }
   scope :in_digital_library,  ->{ where("metadata.date_dl_ingest is not null").order("metadata.date_dl_ingest DESC") }
   scope :not_in_digital_library,  ->{ where("metadata.date_dl_ingest is null") }
   scope :not_approved,  ->{ where(:is_approved => false) }
   scope :has_exemplars,  ->{ where("exemplar is NOT NULL") }
   scope :need_exemplars,  ->{ where("exemplar is NULL") }
   scope :dpla, ->{where(:dpla => true) }
   scope :checked_out, ->{
      joins(:checkouts).where("checkouts.return_at is null")
   }

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :type, presence: true
   validates :creator_death_date, inclusion: { in: 1200..Date.today.year,
      :message => 'must be a 4 digit year.', allow_blank: true
   }

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_save do
      self.parent_metadata_id = 0 if self.parent_metadata_id.blank?
      self.is_approved = false if self.is_approved.nil?
      self.is_manuscript = false if self.is_manuscript.nil?
      self.is_personal_item = false if self.is_personal_item.nil?
      self.discoverability = true if self.discoverability.nil?
      self.collection_facet = nil if !self.collection_facet.nil? && self.collection_facet.downcase == "none"

      # default right statement to not Evaluated
      if self.use_right.blank?
         cne = UseRight.find_by(name: "Copyright Not Evaluated")
         self.use_right = cne
      end
   end

   before_destroy :destroyable?
   def destroyable?
      if self.units.size > 0
         errors[:base] << "cannot delete metadata that is associated with units"
         return false
      end
      return true
   end

   after_create do
      update_attribute(:pid, "tsb:#{self.id}") if self.pid.blank?
   end

   after_update do
      if parent.nil?
         children.each do |child|
            if child.dpla != self.dpla
               if child.ocr_hint_id.nil?
                  child.update(dpla: self.dpla, ocr_hint_id: self.ocr_hint_id)
               else
                  child.update(dpla: self.dpla)
               end
            end
         end
      end
   end

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   def url_fragment
      return null
   end

   def checked_out?
      return false if checkouts.count == 0
      return checkouts.order("checkout_at desc").first.return_at.nil?
   end
   def last_checkout
      return "" if !checked_out?
      return checkouts.order("checkout_at desc").first.checkout_at.strftime("%F %r")
   end

   def checkout
      return if checked_out?
      Checkout.create(metadata: self, checkout_at: DateTime.now)
   end
   def checkin
      return if !checked_out?
      checkouts.order("checkout_at desc").first.update(return_at: DateTime.now)
   end

   # Returns an array of MasterFile objects that are in units to be included in the DL
   def dl_master_files
      if self.new_record?
         return Array.new
      else
         return MasterFile.joins(:metadata).joins(:unit).where('units.include_in_dl = true').where("metadata.id = #{self.id}")
      end
   end

   def in_catalog?
      return self.catalog_key?
   end

   def in_dl?
      return self.date_dl_ingest?
   end

   def personal_item?
      return self.is_personal_item
   end

   def physical_virgo_url
      return "#{Settings.virgo_url}/#{self.catalog_key}"
   end

   def agency_links
      return "" if self.agencies.empty?
      out = ""
      self.agencies.uniq.sort_by(&:name).each do |agency|
         out << "<div><a href='/admin/agencies/#{agency.id}'>#{agency.name}</a></div>"
      end
      return out
   end

   def flag_for_publication
      if self.date_dl_ingest.blank?
        if self.date_dl_update.blank?
            self.update(date_dl_ingest: Time.now)
        else
            self.update(date_dl_ingest: self.date_dl_update, date_dl_update: Time.now)
        end
      else
        self.update(date_dl_update: Time.now)
      end
   end

   def publish_to_test
      xml = Hydra.solr( self, nil )
      RestClient.post "#{Settings.test_solr_url}/virgo/update?commit=true", xml, {:content_type => 'application/xml'}
   end

   # Returns the array of child metadata records
   #
   def children
      return Metadata.where(parent_metadata_id: self.id)
   end

   def typed_children( )
      out = {}
      out[:sirsi] = SirsiMetadata.where(parent_metadata_id: self.id)
      out[:xml] = XmlMetadata.where(parent_metadata_id: id)
      return out
   end

   def parent
      return nil if self.parent_metadata_id.blank? || self.parent_metadata_id == 0
      return Metadata.find_by(id: self.parent_metadata_id)
   end
end

# == Schema Information
#
# Table name: metadata
#
#  id                     :integer          not null, primary key
#  is_approved            :boolean          default(FALSE), not null
#  is_personal_item       :boolean          default(FALSE), not null
#  is_manuscript          :boolean          default(FALSE), not null
#  title                  :text(65535)
#  creator_name           :string(255)
#  catalog_key            :string(255)
#  barcode                :string(255)
#  call_number            :string(255)
#  pid                    :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  exemplar               :string(255)
#  parent_metadata_id     :integer          default(0), not null
#  desc_metadata          :text(65535)
#  discoverability        :boolean          default(TRUE)
#  date_dl_ingest         :datetime
#  date_dl_update         :datetime
#  units_count            :integer          default(0)
#  availability_policy_id :integer
#  use_right_id           :integer
#  dpla                   :boolean          default(FALSE)
#  collection_facet       :string(255)
#  type                   :string(255)      default("SirsiMetadata")
#  external_system        :string(255)
#  external_uri           :string(255)
#  supplemental_system    :string(255)
#  supplemental_uri       :string(255)
#  genre_id               :integer
#  resource_type_id       :integer
#
