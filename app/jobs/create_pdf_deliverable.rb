class CreatePDFDeliverable < BaseJob
   def do_workflow(message)
      unit = message[:unit]

      # all of the scaled down JPEG source files will be pulled down into the
      # assemble deliverable directory
      logger.info "Setting up assemble delivery directory to be used to build the PDF..."
      assemble_dir = Finder.finalization_dir(unit, :assemble_deliverables)
      if Dir.exist? assemble_dir
         logger.info "Removing old deliverables from assembly directory #{assemble_dir}"
         FileUtils.rm_rf(assemble_dir)
      end
      FileUtils.mkdir_p(assemble_dir)

      logger.info "Pull images from IIIF to #{assemble_dir} for PDF generation..."
      unit.master_files.each do |mf|
         dest = File.join(assemble_dir, mf.filename.gsub(/.tif/, ".jpg") )
         iiif_url = "#{Settings.iiif_url}/#{mf.pid}/full/1024,/0/default.jpg"
         logger.info("Download #{iiif_url} to #{dest}")
         iiif_file = open(iiif_url)
         IO.copy_stream(iiif_file, dest)
      end

      # Use File.dirname to omit the unit directory so the zip file is srested directly in the order dir
      assembled_order_dir = File.dirname(assemble_dir)
      pdf_file = File.join( assembled_order_dir, "#{unit.id}.pdf")
      jpg_files = File.join(assemble_dir, "*.jpg")
      logger.info "Covert #{jpg_files} to #{pdf_file}..."
      cvt = `which convert`
      cvt.strip!
      if !File.exist? cvt
         on_error("convert command not found on system!")
      end
      cmd = "#{cvt} -density 150 #{jpg_files} #{pdf_file}"
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
