class DeaccessionMasterFile < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"MasterFile", :originator_id=>message[:master_file].id )
   end

   def do_workflow(message)
      raise "Parameter 'master_file' is required" if message[:master_file].blank?
      raise "Parameter 'user' is required" if message[:user].blank?
      raise "Parameter 'note' is required" if message[:note].blank?

      user = message[:user]
      master_file = message[:master_file]
      unit = master_file.unit
      unit_dir = "%09d" % unit.id

      if master_file.is_clone? || (master_file.is_original? && master_file.reorders.size > 0)
         fatal_error("Cannot deaccession a cloned master file.")
      end

      logger.info "User #{user.computing_id} begins deaccession of Master File #{master_file.pid}"
      deaccession_time = Time.now
      master_file.update( deaccessioned_at:  deaccession_time, deaccession_note: message[:note], deaccessioned_by_id: user.id)

      # remove archive
      archive_file = File.join(ARCHIVE_DIR, "#{unit_dir}", "#{master_file.filename}")
      if not File.exists? archive_file
         log_failure("Archive file #{archive_file} does not exist")
      else
         logger.info "Removing archive #{archive_file}"
         FileUtils.rm(archive_file)
      end

      # remove from iiif
      iiif_fn = master_file.iiif_file()
      if not File.exists? iiif_fn
         log_failure("IIIF file #{iiif_fn} does not exist")
      else
         logger.info "Removing IIIF derivative #{iiif_fn}"
         FileUtils.rm(iiif_fn)
      end

      # If necessary, flag mastergfile as shadowed and flag for publish to DL
      if master_file.in_dl?
         logger.info "File was published to DL; flagging for removal"
         master_file.update(date_dl_update: deaccession_time)
         master_file.metadata.update(date_dl_update: deaccession_time)

         # if unit metdata is different from master file metadata, This
         # this file is uniquely discoverable in DL. Needs to be shadowed
         if master_file.metadata_id != master_file.unit.metadata_id
            master_file.metadata.update(discoverability: false)
         end
      end
   end
end
