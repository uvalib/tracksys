class CreateUnitZip < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id)
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]
      order = unit.order

      # Make sure order delivery dir exists
      delivery_dir = File.join("#{DELIVERY_DIR}", "order_#{order.id}")
      FileUtils.mkdir_p delivery_dir if !Dir.exist?(delivery_dir)

      # IF OCR was requested, generate a single text file containing all of the page OCR results
      ocr_file = nil
      if unit.ocr_master_files
         assemble_dir = File.join(ASSEMBLE_DELIVERY_DIR, "order_#{unit.order.id}", unit.id.to_s)
         ocr_file_name = File.join(assemble_dir, "#{unit.id}.txt")
         logger.info "OCR was requeseted for this unit; generate text file with OCR resuls here: #{ocr_file_name}"
         ocr_file = File.open(ocr_file_name, "w")  # truncate existing and open for write
         unit.master_files.each do |master_file|
            ocr_file.write("#{master_file.filename}\n")
            ocr_file.write("#{master_file.transcription_text}\n")
            logger.info "Added OCR results for master file #{master_file.filename}"
         end
         ocr_file.close
      end

      # generate first zip file name, and fail if it already exists
      file_num = 1
      zip_file = File.join(delivery_dir, "#{unit.id}_#{file_num}.zip")
      if File.exist? zip_file
         if message[:replace]
            logger.info "Removing pre-existing zip deliverables"
            Dir.glob("#{delivery_dir}#{unit.id}_*.zip/") { |z| File.delete z }
         else
            on_error "A .zip archive for unit #{unit.id} already exists."
         end
      end

      # Walk each file in the unit assembly dir and add it to the zip...
      order_path = File.join(ASSEMBLE_DELIVERY_DIR, "order_#{order.id}")
      unit_path = File.join(order_path, "#{unit.id}")
      Dir.foreach(unit_path) do |f|
         next if f == '.' || f == '..' || f == '.DS_Store' || f == '.AppleDouble'

         # build the zip command. cd to the order directory first so
         # unzip will generate only a unit directory
         zip_cmd = "cd #{order_path}; zip #{zip_file} #{File.join(unit.id.to_s, f)}"
         `#{zip_cmd}`

         # if the zip is now too big, start another
         if (File.size(zip_file).to_f / 1024.0**3).to_i > Settings.zip_max_gb.to_i
            file_num += 1
            zip_file = File.join(delivery_dir, "#{unit.id}_#{file_num}.zip")
         end
      end

      on_success "Unit #{unit.id} zipped into #{file_num} zip archive(s)."
   end
end
