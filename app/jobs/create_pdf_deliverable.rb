class CreatePDFDeliverable < BaseJob
   # NOTE: Called from CheckUnitDeliveryMode when all .TIF files are in
   # 30_process_deliverables/[unit_id]
   #
   def do_workflow(message)
      unit = message[:unit]

      # all of the scaled down JPEG source files will be pulled down into the
      # assemble deliverable directory
      logger.info "Setting up assemble delivery directory to be used to build the PDF..."
      assemble_dir = Finder.finalization_dir(unit, :assemble_deliverables)
      assembled_order_dir = File.dirname(assemble_dir)
      if Dir.exist? assembled_order_dir
         logger.info "Removing old deliverables from #{assembled_order_dir}"
         FileUtils.rm_rf(assembled_order_dir)
      end
      FileUtils.mkdir_p(assembled_order_dir)

      # Source tif files resied in 30_process_deliverables. Get the dir
      processing_dir = Finder.finalization_dir(unit, :process_deliverables)

      # Convert all tifs in 30_process_deliverables into a single PDF
      pdf_file = File.join(assembled_order_dir, "#{unit.id}.pdf")
      tif_files = File.join(processing_dir, "*.tif[0]")

      logger.info "Covert #{tif_files} to scaled down JPG..."
      mogrify = `which mogrify`
      mogrify.strip!
      if !File.exist? mogrify
         on_error("mogrify command not found on system!")
      end
      cmd = "#{mogrify} -quiet -resize 1024x -density 150 -format jpg #{tif_files}"
      logger.info("   #{cmd}")
      `#{cmd}`

      jpg_files = File.join(processing_dir, "*.jpg")
      logger.info "Covert #{jpg_files} to #{pdf_file}..."
      cvt = `which convert`
      cvt.strip!
      if !File.exist? cvt
         on_error("convert command not found on system!")
      end
      cmd = "#{cvt} #{jpg_files} #{pdf_file}"
      logger.info("   #{cmd}")
      out = `#{cmd}`

      # See if it appears to have worked...
      if !out.strip.blank?
         on_error("PDF generation failed: #{out}")
      end
      if !File.exist? pdf_file
         on_error("Target PDF #{pdf_file} was not created")
      end

      # Zip the PDF into the delivery directory
      delivery_dir = File.join("#{DELIVERY_DIR}", "order_#{unit.order.id}")
      FileUtils.mkdir_p delivery_dir if !Dir.exist?(delivery_dir)
      zip_file = File.join(delivery_dir, "#{unit.id}.zip")
      logger.info("Zip PDF to #{zip_file}")
      if File.exist? zip_file
         File.delete zip_file
      end

      zip_cmd = "cd #{assembled_order_dir}; zip #{zip_file} #{unit.id}.pdf"
      logger.info "Zip PDF with: #{zip_cmd}"
      `#{zip_cmd}`
      logger.info "Zip deliverable created. Cleanining up #{assemble_dir}"
      FileUtils.rm_rf(assemble_dir)

      unit.update(date_patron_deliverables_ready: Time.now)
      logger.info("DONE")
   end
end
