class PublishToDL < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      unit = Unit.find(message[:unit_id])

      if message[:mode] == :test
         publish_to_test(unit)
      else
         publish_to_prod(unit)
      end
   end

   def publish_to_prod(unit)
      if unit.metadata.availability_policy.nil?
         fatal_error "Metadata #{unit.metadata.id} for Unit #{unit.id} has no availability value.  Please fill in and retry."
      end

      if unit.metadata.discoverability.nil?
         fatal_error "Metadata #{unit.metadata.id} for Unit #{unit.id} has no discoverability value.  Please fill in and retry."
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

      # Lastly, flag the deliverables ready date if it is not already set
      if unit.date_dl_deliverables_ready.blank?
         unit.update(date_dl_deliverables_ready: Time.now)
         logger.info "Unit #{unit.id} is ready for ingestion into the DL."
      else
         logger.info "Unit #{unit.id} and #{unit.master_files_count} master files have been flagged for an update in the DL"
      end
   end

   def publish_to_test(unit)
      if unit.metadata.discoverability
         logger.info "Publish unit ID #{unit.id} to test"
         begin
            unit.metadata.publish_to_test
         rescue Exception=>e
            log_failure("Unable to publish unit #{unit.id} metadata #{unit.metadata.id}: #{e.message}")
         end
      end
      unit.master_files.each do |mf|
         if mf.metadata.discoverability && unit.metadata.id != mf.metadata.id
            logger.info "Publish master file ID #{mf.id} to test"
            begin
               mf.metadata.publish_to_test
            rescue Exception=>e
               log_failure("Unable to publish masterfile #{mf.id} metadata #{mf.metadata.id}: #{e.message}")
            end
         end
      end
   end
end
