module Publishable
   extend ActiveSupport::Concern

   included do
      scope :dpla, ->{where(:dpla => true) }
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

   def in_dpla?
      return dpla && (!date_dl_ingest.blank? || !date_dl_update.blank?)
   end

   def physical_virgo_url
      return "#{Settings.virgo_url}/#{self.catalog_key}"
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

      begin
         # regenerate the IIIF man
         iiif_url = "#{Settings.iiif_manifest_url}/pidcache/#{self.pid}?refresh=true"
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
