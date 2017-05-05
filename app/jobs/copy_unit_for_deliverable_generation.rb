class CopyUnitForDeliverableGeneration < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)

      unit = message[:unit]
      source_dir = message[:source_dir]
      unit_dir = "%09d" % unit.id

      # Set mode flags
      if message[:mode] == "both"
         logger.info "Unit #{unit.id} will have deliverables generated for Patron and DL"
         modes = ['dl', 'patron']
      elsif message[:mode] == "dl" || message[:mode] == "patron"
         modes = [ message[:mode] ]
      else
         on_error "Unknown mode '#{message[:mode]}' passed to copy_unit_for_deliverable_generation_processor"
      end

      # For each mode specified, move files into processing dir and kick of processing
      modes.each do |mode|
         destination_dir = File.join(PROCESS_DELIVERABLES_DIR, mode, unit_dir)
         FileUtils.mkdir_p(destination_dir)

         # copy all of the master files for this unit to the processing directory based on MODE
         logger.debug("Copying all master files from #{source_dir} to #{destination_dir}")
         unit.master_files.each do |master_file|
            begin
               FileUtils.cp(File.join(source_dir, master_file.filename), File.join(destination_dir, master_file.filename))
            rescue Exception => e
               on_error "Can't copy source file '#{master_file.filename}': #{e.message}"
            end

            # compare MD5 checksums
            source_md5 = Digest::MD5.hexdigest(File.read(File.join(source_dir, master_file.filename)))
            dest_md5 = Digest::MD5.hexdigest(File.read(File.join(destination_dir, master_file.filename)))
            if source_md5 != dest_md5
               on_error "Failed to copy source file '#{master_file.filename}': MD5 checksums do not match"
            end
         end
         logger.debug("All master files copied")

         # If the copy was successful, start processing for this batch based on mode
         if mode == 'patron'
            logger.info "Unit #{unit.id} has been successfully copied to #{destination_dir} so patron deliverables can be made."
            QueuePatronDeliverables.exec_now({ :unit => unit, :source => destination_dir }, self)
            if message[:skip_delivery_check].nil?
               CreateUnitZip.exec_now( { unit: unit }, self)
               CheckOrderReadyForDelivery.exec_now( { :order_id => unit.order_id}, self  )
            else
               CreateUnitZip.exec_now( { unit: unit, replace: true}, self)
            end
         elsif mode == 'dl'
            logger.info "Unit #{unit.id} has been successfully copied to #{destination_dir} so Digital Library deliverables can be made."
            CreateDlDeliverables.exec_now({ :unit => unit, :source => destination_dir }, self)
         end

      end

      # If a unit has not already been archived (i.e. this unit did not arrive at this processor
      # from start_ingest_from_archive) archive it - unless it is a re-order
      if unit.date_archived.blank? && unit.reorder == false
         logger.info "Because this unit has not already been archived, it is being sent to the archive."
         SendUnitToArchive.exec_now({ :unit => unit, :internal_dir =>true, :source_dir => IN_PROCESS_DIR }, self)
      elsif unit.reorder == true
         logger.info "Cleaning up in_process files for completed re-order"
         MoveCompletedDirectoryToDeleteDirectory.exec_now({ :unit_id => unit.id, :source_dir => IN_PROCESS_DIR}, self)
      end
   end
end
