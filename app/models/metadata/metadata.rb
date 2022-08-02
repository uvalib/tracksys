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
   has_many :orders, -> { distinct }, :through => :units
   has_many :job_statuses, :as => :originator, :dependent => :destroy

   has_many :agencies, -> { distinct }, :through => :orders
   has_many :customers, -> { distinct }, :through => :orders
   has_many :checkouts

   #------------------------------------------------------------------
   # scopes
   #-----------------------------------------------------------------
   scope :checked_out, ->{
      joins(:checkouts).where("checkouts.return_at is null")
   }
   scope :in_digital_library,  ->{ where("metadata.date_dl_ingest is not null").order("metadata.date_dl_ingest DESC") }
   scope :not_in_digital_library,  ->{ where("metadata.date_dl_ingest is null") }
   scope :in_ap_trust,  ->{ joins(:ap_trust_status).where('ap_trust_statuses.status=?', 'Success') }

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :type, presence: true

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_create do
      self.preservation_tier_id = 1 if self.preservation_tier_id.blank?
   end
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

      if self.changes.has_key?("preservation_tier_id")
         # once sent to APTrust, disallow change to lesser tier
         change = self.changes["preservation_tier_id"]
         # 1: backed up, 2: 1+duplicated once, 3: 1+duplicated multiple places
         # change[0] is the current value, change[1] is the update
         if !change[0].nil? && change[0] > 1 && change[1] < change[0]
            # revert back to original backed-up status
            Rails.logger.info "Metadata #{self.id} cancel downgrade of preservation tier id #{change[0]} to #{change[1]}"
            self.preservation_tier_id = change[0]
            self.changes.delete("preservation_tier_id")
         else
            # if this item has child metadata records, update all to match
            Rails.logger.info "Metadata #{self.id} set preservation tier id to #{self.preservation_tier_id}"
            children = Metadata.where("parent_metadata_id=? and (preservation_tier_id is null or preservation_tier_id < ?)",
               self.id, self.preservation_tier_id)
            Rails.logger.info "Updating #{children.count} child metadata records to match preservation settings"
            children.update_all(preservation_tier_id: self.preservation_tier_id)
         end
      end
   end

   before_destroy do
      if self.units.size > 0
         errors[:base] << "cannot delete metadata that is associated with units"
         return false
      end
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
      page = 0 # manifests are 0 based
      master_files.each do |mf|
         if mf.exemplar == true
            info = {url: mf.link_to_image(size), page: page, id: mf.id, filename: mf.filename, filesize: mf.filesize, pid: mf.pid}
            return info
         else
            page += 1
         end
      end
      mf = master_files.first
      info = {url: mf.link_to_image(size), page: 1, id: mf.id, filename: mf.filename, filesize: mf.filesize, pid: mf.pid}
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

   def collection_name
      collection_id
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
