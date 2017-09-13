class CreateDlDeliverables < BaseJob

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      source = message[:source]
      metadata = unit.metadata

      # Sanity checks:
      if metadata.availability_policy.nil?
         on_error "Metadata #{metadata.id} for Unit #{unit.id} has no availability value.  Please fill in and restart ingestion."
      end
      if metadata.discoverability.nil?
         on_error "Metadata #{metadata.id} for Unit #{unit.id} has no discoverability value.  Please fill in and restart ingestion."
      end

      # All ingestable objects have a date_dl_ingest attribute which can be updated at this time.
      # Also, send all masterfiles to IIIF server (this is the generation of DL deliverables)
      metadata.update(date_dl_ingest: Time.now)
      unit.master_files.each do |mf|
         if mf.metadata.id != unit.metadata.id
            mf.metadata.update(date_dl_ingest: Time.now)
         end
         mf.update(date_dl_ingest: Time.now)
         file_path = File.join(source, mf.filename)
         PublishToIiif.exec_now({ :source => file_path, :master_file_id=> mf.id }, self)
      end

      # All deliverables generated; update timestamp and cleanup
      unit.update(date_dl_deliverables_ready: Time.now)
      logger.info "Unit #{unit.id} is ready for ingestion into the DL."

      if source.match("finalization")
         logger().debug("Removing processing directory #{source}/...")
         FileUtils.rm_rf(source)
         logger.info("Files for unit #{unit.id} copied for the creation of DL deliverables have now been deleted.")
      end
   end
end
