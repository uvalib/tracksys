class SirsiMetadata < Metadata
   has_and_belongs_to_many :components, join_table: :sirsi_metadata_components

   scope :dpla, ->{where(:dpla => true) }

   validates :use_right, presence: true
   validates :desc_metadata, presence: false
   validates :external_system, presence: false
   validates :external_uri, presence: false
   validates :title, presence: true
   validates :creator_death_date, inclusion: { in: 1200..Date.today.year,
      :message => 'must be a 4 digit year.', allow_blank: true
   }

   before_save do
      if self.availability_policy_id.blank?
         pub_info = Virgo.get_marc_publication_info(self.catalog_key)
         if !pub_info[:year].blank? && pub_info[:year].to_i < 1923
            self.availability_policy_id = 1 # PUBLIC
         end
      end
      self.is_personal_item = false if self.is_personal_item.blank?
   end

   before_destroy :destroyable?
   def destroyable?
      if self.components.size > 0
         errors[:base] << "cannot delete Sirsi metadata that is associated with components"
         return false
      end
      return true
   end

   def url_fragment
      return "sirsi_metadata"
   end

   def in_catalog?
      return self.catalog_key?
   end

   def in_dl?
      return self.date_dl_ingest?
   end
   def can_publish?
      return self.units.where("include_in_dl=?", true).count > 0
   end

   def physical_virgo_url
      return "#{Settings.virgo_url}/#{self.catalog_key}"
   end

   def publish
      if self.date_dl_ingest.blank?
        if self.date_dl_update.blank?
            self.update(date_dl_ingest: Time.now)
        else
            self.update(date_dl_ingest: self.date_dl_update, date_dl_update: Time.now)
        end
      else
        self.update(date_dl_update: Time.now)
      end

      begin
         iiif_url = "#{Settings.iiif_manifest_url}/pid/#{self.pid}?refresh=true"
         Rails.logger.info "Regenerate IIIF manifest with #{iiif_url}"
         resp = RestClient.get iiif_url
         if resp.code.to_i != 200
            Rails.logger.error "Unable to generate IIIF manifest: #{resp.body}"
         else
            Rails.logger.info "IIIF manifest regenerated"
         end
      rescue Exception => e
         Rails.logger.error "Unable to generate IIIF manifest: #{e}"
      end

      # Call the reindex API for sirsi items
      if self.type == "SirsiMetadata" && !self.catalog_key.blank?
         Rails.logger.info "Call the reindex service for #{self.id} - #{self.catalog_key}"
         resp = RestClient.put "#{Settings.reindex_url}/api/reindex/#{self.catalog_key}", ""
         if resp.code.to_i == 200
            Rails.logger.info "#{self.catalog_key} reindex request successful"
         else
            Rails.logger.warn "#{self.catalog_key} reindex request FAILED: #{resp.code}: #{resp.body}"
         end
      end
   end
end
