class RecreatePatronDeliverables < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      # This workflow is only available after a successful finalize. Images will be in the archive.
      # Move them to the finalization directory and use that to recreate deliverables
      unit = Unit.find(message[:unit_id])
      unit_dir = File.join(Settings.production_mount, "finalization", unit.directory)
      assemble_dir = File.join(Settings.production_mount, "finalization", "tmp", unit.directory)

      if unit.reorder
         logger.info "Recreating deliverables for a reorder"
         # in this case, each cloned masterfile will have a reference to the original.
         # use this to get to the original unit and recalculate directories
         copy_original_files(unit, unit_dir)
      else
         archive_dir = File.join(ARCHIVE_DIR, unit.directory)
         logger.info "Recreating deliverables the archive #{archive_dir}"
         FileUtils.cp_r  archive_dir, unit_dir
      end

      begin
         if unit.intended_use.deliverable_format == "pdf"
            logger.info("Unit #{unit.id} requires the re-creation of PDF patron deliverables.")
            Patron.pdf_deliverable(unit, logger)
         else
            logger.info("Unit #{unit.id} requires the re-creation of patron deliverables.")
            call_number = nil
            location = nil
            if unit.metadata.type == "SirsiMetadata"
               sm = unit.metadata.becomes(SirsiMetadata)
               call_number = sm.call_number
               location = sm.get_full_metadata[:location]
            end
            unit.master_files.each do |mf|
               src = File.join(unit_dir, mf.filename)
               Patron.create_deliverable(unit, mf, src, assemble_dir, call_number, location, logger )
            end
            Patron.zip_deliverables(unit, logger)
         end

         unit.update(date_patron_deliverables_ready: Time.now)
         logger.info("Deliverables re-created. Date deliverables ready has been updated.")

         logger.info("Cleaning up working directories")
         FileUtils.rm_rf(unit_dir)
         FileUtils.rm_rf(assemble_dir)
         logger.info("Success")
      rescue Exception => e
         fatal_error( e.message )
      end
   end

   def copy_original_files(unit, unit_dir)
      unit.master_files.each do |mf|
         # Cloned files can come from many src units. Get original unit for
         # the current master file and figure out where to find it in the archive
         orig_unit = mf.original.unit
         archive_dir = File.join(ARCHIVE_DIR, orig_unit.directory)
         orig_archived_file = File.join(archive_dir, mf.original.filename)

         logger.info "Copy original master file from #{orig_archived_file} to #{unit_dir}"
         FileUtils.cp(orig_archived_file, File.join(unit_dir, mf.filename))
      end
   end
end
