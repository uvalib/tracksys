class Metadata < ApplicationRecord

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :availability_policy, counter_cache: true, optional: true
   belongs_to :use_right, counter_cache: true, optional: true

   belongs_to :ocr_hint, optional: true
   belongs_to :preservation_tier, optional: true
   has_one :ap_trust_status

   belongs_to :external_system, class_name: 'ExternalSystem', foreign_key: 'external_system_id', optional: true
   belongs_to :supplemental_system, class_name: 'ExternalSystem', foreign_key: 'supplemental_system_id', optional: true

   has_many :master_files
   has_many :units
   has_many :orders, :through => :units
   has_many :job_statuses, :as => :originator, :dependent => :destroy

   has_many :agencies, :through => :orders
   has_many :customers, :through => :orders
   has_many :checkouts

   #------------------------------------------------------------------
   # scopes
   #-----------------------------------------------------------------
   scope :checked_out, ->{
      joins(:checkouts).where("checkouts.return_at is null")
   }
   scope :in_digital_library,  ->{ where("metadata.date_dl_ingest is not null").order("metadata.date_dl_ingest DESC") }
   scope :not_in_digital_library,  ->{ where("metadata.date_dl_ingest is null") }

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :type, presence: true

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_save do
      self.parent_metadata_id = 0 if self.parent_metadata_id.blank?
      self.is_manuscript = false if self.is_manuscript.nil?
      self.is_personal_item = false if self.is_personal_item.nil?
      self.collection_facet = nil if !self.collection_facet.nil? && self.collection_facet.downcase == "none"

      # default right statement to not Evaluated
      if self.use_right.blank?
         cne = UseRight.find_by(name: "Copyright Not Evaluated")
         self.use_right = cne
      end

      if self.changes.has_key? "preservation_tier_id"
         # once sent to APTrust, disallow change to lesser tier
         change = self.changes["preservation_tier_id"]
         puts "change in preservation #{change}"
         if !change[0].nil? && change[0] > 1 && change[1] == 1
            # revert back to original backed-up status 
            self.preservation_tier_id = change[0]
            self.changes.delete("preservation_tier_id")
         end
      else 
         if preservation_tier.blank?
            units.each do |u|
               if u.intended_use_id == 110
                  preservation_tier_id = 2 # duplicated
                  break
               end
            end
         end
      end
   end

   after_save do 
      if saved_changes.has_key? "preservation_tier_id" && self.type != "ExternalMetadata"
         if self.preservation_tier_id > 1 && self.ap_trust_status.nil?
            if Settings.aptrust_enabled == "true"
               PublishToApTrust.exec({metadata: self})
            end
         end
      end
   end

   before_destroy do
      if self.units.size > 0
         errors[:base] << "cannot delete metadata that is associated with units"
         return false
      end
      return true
   end

   after_create do
      update_attribute(:pid, "tsb:#{self.id}") if self.pid.blank?
   end


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

   def has_exemplar?
      return master_files.where(exemplar: true).count > 0
   end

   # return a hash containing URL, filename, PID, ID and page number for exemplar
   # Optionally specify a size for the thumbnail. Small is the default
   def exemplar_info( size = :small )
      mf = master_files.where(exemplar: true).first
      page = mf.filename.split("_")[1].split(".")[0].to_i
      info = {url: mf.link_to_image(size), page: page, id: mf.id, filename: mf.filename, pid: mf.pid}
      return info
   end

   def agency_links
      return "" if self.agencies.empty?
      out = ""
      self.agencies.uniq.sort_by(&:name).each do |agency|
         out << "<div><a href='/admin/agencies/#{agency.id}'>#{agency.name}</a></div>"
      end
      return out
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
      out[:external] = ExternalMetadata.where(parent_metadata_id: id)
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
#  external_uri           :string(255)
#  supplemental_uri       :string(255)
#  collection_id          :string(255)
#  ocr_hint_id            :integer
#  ocr_language_hint      :string(255)
#  use_right_rationale    :string(255)
#  creator_death_date     :integer
#  qdc_generated_at       :datetime
#  preservation_tier_id   :bigint(8)
#  external_system_id     :bigint(8)
#  supplemental_system_id :bigint(8)
#
