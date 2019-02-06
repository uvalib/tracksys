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
         assemble_dir = Finder.finalization_dir(unit, :assemble_deliverables)
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
            logger.info "Removing pre-existing zip deliverables..."
            Dir.glob("#{delivery_dir}/*.zip") do |zf|
               logger.info "Removing #{zf}..."
               File.delete zf
            end
         else
            fatal_error "A .zip archive for unit #{unit.id} already exists."
         end
      end

      # unit_path is the path to the unit tif/jpg files
      # EX: /digiserv-production/finalization/40_assemble_deliverables/order_10375/52725
      unit_path = Finder.finalization_dir(unit, :assemble_deliverables)

      # Omit the unit directory so the zip file can be created with one subdir
      # EX: /digiserv-production/finalization/40_assemble_deliverables/order_10375
      zip_order_path = unit_path.split('/')[0...-1].join('/')

      # Walk each file in the unit assembly dir and add it to the zip...
      logger.info "Create #{zip_file}..."
      Dir.glob("#{unit_path}/*").sort.each do |f|
         next if f == '.DS_Store' || f == '.AppleDouble'
         # build the zip command. cd to the order directory first so
         # unzip will generate only a unit directory
         logger.info "Add #{f} to zip"
         zip_cmd = "cd #{zip_order_path}; zip #{zip_file} #{File.join(unit.id.to_s, File.basename(f))}"
         `#{zip_cmd}`

         # if the zip is now too big, start another
         if (File.size(zip_file).to_f / 1024.0**3).to_i > Settings.zip_max_gb.to_i
            file_num += 1
            zip_file = File.join(delivery_dir, "#{unit.id}_#{file_num}.zip")
            logger.info "Create #{zip_file}"
         end
      end

      logger.info "Unit #{unit.id} zipped into #{file_num} zip archive(s)."
   end
end
