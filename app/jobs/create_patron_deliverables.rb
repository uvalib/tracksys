class CreatePatronDeliverables < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      # this can be called as part of a re-order or after finalization. for re-orders, the images will already exist in unit_dir
      unit = Unit.find(message[:unit_id])
      unit_dir = File.join(Settings.production_mount, "finalization", unit.directory)
      assemble_dir = File.join(Settings.production_mount, "finalization", "tmp", unit.directory)

      if !unit_images_available?(unit, assemble_dir)
         if unit.reorder
            logger.info "Creating deliverables for a reorder"
            # in this case, each cloned masterfile will have a reference to the original.
            # use this to get to the original unit and recalculate directories
            copy_original_files(unit, unit_dir)
         else
            archive_dir = File.join(ARCHIVE_DIR, unit.directory)
            logger.info "Creating deliverables from the archive #{archive_dir}"
            FileUtils.cp_r  archive_dir, unit_dir
         end
      else
         logger.info "All files needed to generate unit #{unit.id} deliverables exist in #{unit_dir}"
      end

      begin
         if unit.intended_use.deliverable_format == "pdf"
            logger.info("Unit #{unit.id} requires the creation of PDF patron deliverables.")
            Patron.pdf_deliverable(unit, logger)
         else
            logger.info("Unit #{unit.id} requires the creation of patron deliverables.")
            call_number = nil
            location = nil
            if unit.metadata.type == "SirsiMetadata"
               sm = unit.metadata.becomes(SirsiMetadata)
               call_number = sm.call_number
               location = sm.get_full_metadata[:location]
            end
            FileUtils.mkdir_p(assemble_dir) if !Dir.exist? assemble_dir
            unit.master_files.each do |mf|
               src = File.join(unit_dir, mf.filename)
               Patron.create_deliverable(unit, mf, src, assemble_dir, call_number, location, logger )
            end
            Patron.zip_deliverables(unit, logger)
         end

         unit.update(date_patron_deliverables_ready: Time.now)
         logger.info("Deliverables created. Date deliverables ready has been updated.")

         logger.info("Cleaning up working directories")
         FileUtils.rm_rf(unit_dir)
         FileUtils.rm_rf(assemble_dir)
         logger.info("Success")
      rescue Exception => e
         fatal_error( e.message )
      end
   end

   def unit_images_available? (unit, unit_dir)
      return false if !Dir.exist? unit_dir
      return Dir[File.join(unit_dir, '*.tif')].count == unit.master_files.count
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
