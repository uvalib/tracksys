class PublishToApTrust < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Metadata", :originator_id=>message[:metadata].id )
   end

   def do_workflow(message)
      raise "Parameter 'metadata' is required" if message[:metadata].blank?
      metadata = message[:metadata]

      logger.info "Create new bag"
      storage = "Standard"
      storage = "Glacier-VA" if metadata.preservation_tier_id == 1
      bag = Bagit::Bag.new({bag: "tracksys-#{metadata.type.downcase}-#{metadata.id}", 
         title: metadata.title, pid: metadata.pid, storage: storage}, logger)

      logger.info "Adding masterfiles to bag..."
      metadata.master_files.each do |mf|
         logger.info "   #{mf.filename}"
         unit = mf.unit
         mfp = File.join(Settings.archive_mount, unit.directory, mf.filename)
         bag.add_file( mf.filename, mfp)
      end

      logger.info "Add desc_metadata"
      bag.add_file("#{metadata.pid}.xml") { |io| io.write Hydra.desc(metadata) }
      
      logger.info "Generate manifests"
      bag.generate_manifests

      logger.info "Generate tar file"
      tarfile = bag.tar

      # create APTrust status record for this metadata...
      logger.info("Submitting bag to APTrust")
      apt_status = ApTrustStatus.create(metadata: metadata, status: "Submitted")
      etag = ApTrust::submit( tarfile )
      apt_status.update(etag: etag)
      logger.info("Submitted; etag=#{etag}")

      logger.info("cleaning up bag working files")
      bag.cleanup

      # poll APTrust to follow submission status. only when it is done end this job
      logger.info("Polling APTrust to monitor submission status")
      while (true) do 
         sleep(1.minute)

         resp = ApTrust::status(etag)
         if !resp.nil?
            apt_status.update(status: resp[:status], note: resp[:note])  
            logger.info("Status: #{resp[:status]}, stage: #{resp[:stage]}")

            if resp[:status] == "Failed" || resp[:status] == "Success" 
               logger.info("APTrust submission #{resp[:status]}")
               apt_status.update(finished_at: resp[:finished_on], object_id: resp[:object_id])
               break
            end
         end
      end
   end
end