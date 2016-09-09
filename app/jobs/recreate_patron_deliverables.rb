class RecreatePatronDeliverables < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)


      # first, try to locate the original files for the unit.
      # if they are not in IN_PROCESS_DIR, put them there
      unit = message[:unit]
      unit_dir = "%09d" % unit.id
      in_proc_dir = File.join(IN_PROCESS_DIR, unit_dir)
      del_finalized = File.join(DELETE_DIR_FROM_FINALIZATION, unit_dir)
      del_delivered_orders = File.join(DELETE_DIR_DELIVERED_ORDERS, "order_#{unit.order_id}", unit.id.to_s)
      archive_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)

      if Dir.exist? in_proc_dir
         logger.info "Recreating deliverables from data in the in process directory"
      elsif Dir.exist? del_finalized
         logger.info "Recreating deliverables from data in the ready to delete from finalization directory"
         copy_files(unit, del_finalized, in_proc_dir)
      elsif Dir.exist? del_delivered_orders
         logger.info "Recreating deliverables from data in the ready to delete deliverd orders directory"
         copy_files(unit, del_delivered_orders, in_proc_dir)
      else
         logger.info "Recreating deliverables from data in the archive"
         copy_files(unit, archive_dir, in_proc_dir)
      end

      # files are in the correct directory. now regenerate
      CopyUnitForDeliverableGeneration.exec_now({unit: unit, source_dir: in_proc_dir, mode: "patron", skip_delivery_check: true}, self)
      MoveCompletedDirectoryToDeleteDirectory.exec_now({ :unit_id => unit.id, :source_dir => IN_PROCESS_DIR}, self)
   end

   def copy_files( unit, src, dest)
      logger.info "Creating #{dest}"
      FileUtils.mkdir_p(dest)
      unit.master_files.each do |mf|
         begin
            FileUtils.cp(File.join(src, mf.filename), File.join(dest, mf.filename))
         rescue Exception => e
            on_error "Can't copy source file '#{master_file.filename}': #{e.message}"
         end
      end
   end
end
