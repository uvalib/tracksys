class RecreatePatronDeliverables < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)

      # first, try to locate the original files for the unit.
      # if they are not in the in process directory, put them there
      unit = Unit.find(message[:unit_id])
      unit_dir = "%09d" % unit.id
      in_proc_dir = Finder.finalization_dir(unit, :in_process)
      del_finalized = Finder.finalization_dir(unit, :delete_from_finalization)
      del_delivered_orders = Finder.finalization_dir(unit, :delete_from_delivered)
      archive_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)

      # See if in proc exists, and has a tif for each master file in the unit
      if in_proc_complete?(unit, in_proc_dir)
         logger.info "Recreating deliverables from data in the in process directory"
      elsif Dir.exist? del_finalized
         logger.info "Recreating deliverables from data in the ready to delete from finalization directory"
         FileUtils.cp_r del_finalized, File.dirname(in_proc_dir)
      elsif Dir.exist? del_delivered_orders
         if did_deliverable_format_change(unit, del_delivered_orders)
            # Format is different from the files found. Must regenerate from archive
            logger.info "Deliverable changed; creating from data in the archive"
            FileUtils.cp_r archive_dir, File.dirname(in_proc_dir)
         else
            # In this case, deliverbles already exist. Move them into the assemble dir for packaging
            logger.info "Moving deliverables from data in the ready to delete delivered orders directory"
            assemble_dir = Finder.finalization_dir(unit, :assemble_deliverables)
            FileUtils.cp_r del_delivered_orders, assemble_dir

            # since deliverables already exist, just zip them up
            CreateUnitZip.exec_now( { unit: unit, replace: true }, self)

            unit.update_attribute(:date_patron_deliverables_ready, Time.now)
            logger().info("Date patron deliverables ready for unit #{unit.id} has been updated.")
            return
         end
      else
         if unit.reorder
            logger.info "Recreating deliverables for a reorder"
            # in this case, each cloned masterfile will have a reference to the original.
            # use this to get to the original unit and recalculate directories
            copy_original_files_to_in_proc(unit, in_proc_dir)
         else
            logger.info "Recreating deliverables from data in the archive"
            FileUtils.cp_r  archive_dir, in_proc_dir
         end
      end

      # Found files; move to processsinng and recreate deliverables
      CopyUnitForProcessing.exec_now({ :unit => unit}, self)
      CreatePatronDeliverables.exec_now({ unit: unit }, self)
      CreateUnitZip.exec_now( { unit: unit, replace: true}, self)
   end

   def in_proc_complete? (unit, in_proc_dir)
      return false if !Dir.exist? in_proc_dir
      return Dir[File.join(in_proc_dir, '*.tif')].count == unit.master_files.count
   end

   def copy_original_files_to_in_proc(unit, in_proc_dir)
      if !Dir.exists? in_proc_dir
         logger.info "Creating dir #{in_proc_dir}"
         FileUtils.mkdir_p(in_proc_dir)
         FileUtils.chmod(0775, in_proc_dir)
      end

      unit.master_files.each do |mf|
         # Cloned files can come from many src units. Get original unit for
         # the current master file and figure out where to find it in the archive
         orig_unit = mf.original.unit
         archive_dir = File.join(ARCHIVE_DIR, "%09d" % orig_unit.id)
         orig_archived_file = File.join(archive_dir, mf.original.filename)

         logger.info "Copy original master file from #{orig_archived_file} to #{in_proc_dir}"
         FileUtils.cp(orig_archived_file, File.join(in_proc_dir, mf.filename))
      end
   end

   def did_deliverable_format_change(unit, deliverable_dir )
      # Return true if there are no files with the extension matching the
      # current intended use format
      fmt = unit.intended_use.deliverable_format
      fmt = "tiff" if fmt.blank?
      fmt = "tif" if fmt == "tiff"
      fmt = "jpg" if fmt == "jpeg"
      return Dir.glob("#{deliverable_dir}/*.#{fmt}").count == 0
   end
end
