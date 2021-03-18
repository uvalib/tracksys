class PublishToDL < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit = Unit.find(message[:unit_id])

      if unit.metadata.availability_policy.nil?
         fatal_error "Metadata #{unit.metadata.id} for Unit #{unit.id} has no availability value.  Please fill in and retry."
      end

      # Flag metadata for ingest or update
      if unit.metadata.date_dl_ingest.blank?
         unit.metadata.update(date_dl_ingest: Time.now)
      else
         unit.metadata.update(date_dl_update: Time.now)
      end

      # now flag each master file for intest or update...
      unit.master_files.each do |mf|
         if mf.date_dl_ingest.blank?
            mf.update(date_dl_ingest: Time.now)
         else
            mf.update(date_dl_update: Time.now)
         end

         # if master file has its own metadata, set it too
         if mf.metadata.id != unit.metadata.id
            if mf.metadata.date_dl_ingest.blank?
               if mf.metadata.date_dl_update.blank?
                  mf.metadata.update(date_dl_ingest: Time.now)
               else
                  mf.metadata.update(date_dl_ingest: mf.metadata.date_dl_update, date_dl_update: Time.now)
               end
            else
               mf.metadata.update(date_dl_update: Time.now)
            end
         end
      end

      begin
         md_pid = unit.metadata.pid
         iiif_url = "#{Settings.iiif_manifest_url}/pidcache/#{md_pid}?refresh=true"
         logger.info "Regenerate IIIF manifest with #{iiif_url}"
         resp = RestClient.get iiif_url
         if resp.code.to_i != 200
            logger.error "Unable to regenerate IIIF manifest: #{resp.body}"
         else
            logger.info "IIIF manifest regenerated"
         end
      rescue Exception => e
         logger.error "Unable to regenerate IIIF manifest: #{e}"
      end

      # Call the reindex API for sirsi items
      if unit.metadata.type == "SirsiMetadata" && !unit.metadata.catalog_key.blank?
         logger.info "Call the reindex service for #{unit.metadata.id} - #{unit.metadata.catalog_key}"
         resp = RestClient.put "#{Settings.reindex_url}/api/reindex/#{unit.metadata.catalog_key}", ""
         if resp.code.to_i == 200
            logger.info "#{unit.metadata.catalog_key} reindex request successful"
         else
            logger.warn "#{unit.metadata.catalog_key} reindex request FAILED: #{resp.code}: #{resp.body}"
         end
      end

      # Lastly, flag the deliverables ready date if it is not already set
      if unit.date_dl_deliverables_ready.blank?
         unit.update(date_dl_deliverables_ready: Time.now)
         logger.info "Unit #{unit.id} is ready for ingestion into the DL."
      else
         logger.info "Unit #{unit.id} and #{unit.master_files_count} master files have been flagged for an update in the DL"
      end
   end
end
