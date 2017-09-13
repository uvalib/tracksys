class RecreatePatronDeliverables < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)

      # first, try to locate the original files for the unit.
      # if they are not in the in process directory, put them there
      unit = Unit.find(message[:unit_id])
      unit_dir = "%09d" % unit.id
      in_proc_dir = unit.get_finalization_dir(:in_process)
      del_finalized = unit.get_finalization_dir(:delete_from_finalization)
      del_delivered_orders = unit.get_finalization_dir(:delete_from_delivered)
      archive_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)

      if Dir.exist? in_proc_dir
         logger.info "Recreating deliverables from data in the in process directory"
      elsif Dir.exist? del_finalized
         logger.info "Recreating deliverables from data in the ready to delete from finalization directory"
         copy_files(unit, del_finalized, in_proc_dir)
      elsif Dir.exist? del_delivered_orders
         if did_deliverable_format_change(unit, del_delivered_orders)
            # Format is different from the files found. Must regenerate from archive
            logger.info "Deliverable changed; creating from data in the archive"
            copy_files(unit, archive_dir, in_proc_dir)
         else
            # In this case, deliverbles already exist. Move them into the assemble dir for packaging
            logger.info "Moving deliverables from data in the ready to delete delivered orders directory"
            assemble_dir = unit.get_finalization_dir(:assemble_deliverables)
            copy_files(unit, del_delivered_orders, assemble_dir)

            # since deliverables already exist, just zip them up
            CreateUnitZip.exec_now( { unit: unit }, self)

            unit.update_attribute(:date_patron_deliverables_ready, Time.now)
            logger().info("Date patron deliverables ready for unit #{unit.id} has been updated.")
            return
         end
      else
         logger.info "Recreating deliverables from data in the archive"
         copy_files(unit, archive_dir, in_proc_dir)
      end

      # files are in the correct directory. now regenerate
      CopyUnitForDeliverableGeneration.exec_now({unit: unit, source_dir: in_proc_dir, mode: "patron", skip_delivery_check: true}, self)
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

   def copy_files( unit, src, dest)
      logger.info "Creating #{dest}"
      FileUtils.mkdir_p(dest)
      FileUtils.chmod(0775, dest)
      unit.master_files.each do |mf|
         begin
            src_file = File.join(src, mf.filename)
            if File.exist? src_file
               FileUtils.cp(src_file, File.join(dest, mf.filename))
            else
               # must be a jpg deliverable... try that
               jpg_file = mf.filename.gsub(/.tif/, ".jpg")
               FileUtils.cp(File.join(src, jpg_file), File.join(dest, jpg_file))
            end
         rescue Exception => e
            on_error "Can't copy source file '#{mf.filename}': #{e.message}"
         end
      end
   end
end
