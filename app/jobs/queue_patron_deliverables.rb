class QueuePatronDeliverables < BaseJob

   def do_workflow(message)

      # Validate incoming messages
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      source = message[:source]

      call_number = nil
      location = nil
      if unit.metadata.type == "SirsiMetadata"
         sm = unit.metadata.becomes(SirsiMetadata)
         call_number = sm.call_number
         location = sm.get_full_metadata[:location]
      end

      # if a prior set of deliveranbles is in the assembly dir, remove them
      assemble_dir = Finder.finalization_dir(unit, :assemble_deliverables)
      if Dir.exist? assemble_dir
         logger.info "Removing old deliverables from assembly directory #{assemble_dir}"
         FileUtils.rm_rf(assemble_dir)
      end

      ocr_file = nil
      if unit.ocr_master_files
         FileUtils.mkdir_p(assemble_dir)
         logger.info "OCR was requeseted for this unit; generate text file with OCR results"
         ocr_file_name = File.join(assemble_dir, "#{unit.id}.txt")
         ocr_file = File.open(ocr_file_name, "w")  # truncate existing and open for write
      end
      unit.master_files.each do |master_file|
         file_source = File.join(source, master_file.filename)
         CreatePatronDeliverables.exec_now({ unit: unit, :master_file => master_file,
            :source => file_source, :call_number => call_number, :title => unit.metadata.title,
            :location => location, :personal_item => unit.metadata.personal_item?}, self)

         # if OCR is present, include a single transcript file in the assembly dir
         if !ocr_file.nil?
            ocr_file.write("#{master_file.filename}\n")
            ocr_file.write("#{master_file.transcription_text}\n")
         end

         # also send to IIIF server for thumbnail generation and visibility from archivesspace
         if unit.reorder == false
            PublishToIiif.exec_now({ :source => file_source, :master_file_id=> master_file.id }, self)
         end
      end

      if !ocr_file.nil?
         ocr_file.close
      end

      logger().info("All patron deliverables created")
      logger().info("Removing patron processing directory: #{source}")
      FileUtils.rm_rf(source)
      logger().info("Files for unit #{unit.id} copied for the creation of patron deliverables have now been deleted.")

      unit.update_attribute(:date_patron_deliverables_ready, Time.now)
      logger().info("Date patron deliverables ready for unit #{unit.id} has been updated.")
   end
end
