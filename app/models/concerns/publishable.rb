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
      return dpla && discoverability && (!date_dl_ingest.blank? || !date_dl_update.blank?)
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
   end

   def publish_to_test
      ok, payload = Hydra.solr( self, nil )
      if ok == true
         RestClient.post "#{Settings.test_solr_url}/virgo/update?commit=true", payload, {:content_type => 'application/xml'}
      else
         Rails.logger.warn "Error creating Solr index record (#{payload})"
      end
   end

end
