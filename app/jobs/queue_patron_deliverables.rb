class QueuePatronDeliverables < BaseJob

   def do_workflow(message)

      # Validate incoming messages
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      source = message[:source]
      # NOTES: in this case source is File.join(PROCESS_DELIVERABLES_DIR, 'patron', unit_dir)
      # where unit_dir is the 9-digit, 0-padded unit ID

      call_number = nil
      location = nil
      if unit.metadata.type == "SirsiMetadata"
         sm = unit.metadata.becomes(SirsiMetadata)
         call_number = sm.call_number
         location = sm.get_full_metadata[:location]
      end

      # if a prior set of deliveranbles is in the assembly dir, remove them
      assemble_dir = File.join(ASSEMBLE_DELIVERY_DIR, "order_#{unit.order.id}", unit.id.to_s)
      if Dir.exist? assemble_dir
         logger.info "Removing old deliverables from assembly directory #{assemble_dir}"
         FileUtils.rm_rf(assemble_dir)
      end

      unit.master_files.each do |master_file|
         file_source = File.join(source, master_file.filename)
         CreatePatronDeliverables.exec_now({ unit: unit, :master_file => master_file,
            :source => file_source, :call_number => call_number, :title => unit.metadata.title,
            :location => location, :personal_item => unit.metadata.personal_item?}, self)

         # also send to IIIF server for thumbnail generation and visibility from archivesspace
         if unit.reorder == false
            PublishToIiif.exec_now({ :source => file_source, :master_file_id=> master_file.id }, self)
         end
      end

      logger().info("All patron deliverables created")
      logger().info("Removing patron processing directory: #{source}")
      FileUtils.rm_rf(source)
      logger().info("Files for unit #{unit.id} copied for the creation of patron deliverables have now been deleted.")

      unit.update_attribute(:date_patron_deliverables_ready, Time.now)
      logger().info("Date patron deliverables ready for unit #{unit.id} has been updated.")
   end
end
