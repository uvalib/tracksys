class CreateDlDeliverables < BaseJob

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      source = message[:source]
      metadata = unit.metadata

      # First, update the date the unit was queued for ingest...
      unit.update_attribute(:date_queued_for_ingest, Time.now)
      logger.info "Date queued for ingest for Unit #{unit.id} has been updated."

      # Sanity checks:
      if metadata.availability_policy.nil?
         on_error "Metadata #{metadata.id} for Unit #{unit.id} has no availability value.  Please fill in and restart ingestion."
      end
      if metadata.discoverability.nil?
         on_error "Metadata #{metadata.id} for Unit #{unit.id} has no discoverability value.  Please fill in and restart ingestion."
      end
      if metadata.discoverability == false
         on_error "Metadata #{metadata.id} for Unit #{unit.id} has is set to not discoverable!"
      end
      if metadata.indexing_scenario.nil?
         metadata.update(indexing_scenario: IndexingScenario.find(1) )
         logger.info "Metadata #{metadata.id} for Unit #{unit.id} has no indexing scenario selected so it is assumed to use the default scenario."
      end

      # All ingestable objects have a date_dl_ingest attribute which can be updated at this time.
      # Also, send all masterfiles to IIIF server (this is the generation of DL deliverables)
      unit.update(date_dl_ingest: Time.now)
      metadata.update(date_dl_ingest: Time.now)
      unit.master_files.each do |mf|
         mf.update(date_dl_ingest: Time.now)
         file_path = File.join(source, object.filename)
         PublishToIiif.exec_now({ :source => file_path, :master_file_id=> object.id }, self)
      end

      # All deliverables generated; update timestamp and cleanup
      unit.update_attribute(:date_dl_deliverables_ready, Time.now)
      logger.info "Unit #{unit.id} is ready for ingestion into the DL."

      if source.match("#{FINALIZATION_DIR_MIGRATION}") or source.match("#{FINALIZATION_DIR_PRODUCTION}")
         del_dir = File.dirname(source)
         logger().debug("Removing processing directory #{del_dir}/...")
         FileUtils.rm_rf(del_dir)
         logger.info("Files for unit #{unit.id} copied for the creation of #{@dl} deliverables have now been deleted.")
      end
   end
end
