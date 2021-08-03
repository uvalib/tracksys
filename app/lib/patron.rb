module Patron
   def self.zip_deliverables(unit, logger = Logger.new(STDOUT) )
      # Make sure order delivery dir exists and is empty
      logger.info "Zipping deliverables for unit #{unit.id}"
      order = unit.order
      delivery_dir = File.join("#{DELIVERY_DIR}", "order_#{order.id}")
      if !Dir.exist?(delivery_dir)
         logger.info "Create delivery dir #{delivery_dir}"
         FileUtils.mkdir_p delivery_dir
      else
         Dir.glob("#{delivery_dir}/*.zip") do |zf|
            logger.info "Remove pre-existing zip deliverable #{zf}"
            File.delete zf
         end
      end

      # IF OCR was requested, generate a single text file containing all of the page OCR results
      ocr_file = nil
      if unit.ocr_master_files
         assemble_dir = File.join(Settings.production_mount, "finalization", "tmp", unit.directory)
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


      # Walk each file in the unit assembly dir and add it to the zip...
      file_num = 1
      zip_file = File.join(delivery_dir, "#{unit.id}_#{file_num}.zip")
      tmp_dir = File.join(Settings.production_mount, "finalization", "tmp")
      assemble_dir = File.join(tmp_dir, unit.directory)
      logger.info "Create #{zip_file}..."
      Dir.glob("#{assemble_dir}/*").sort.each do |f|
         next if f == '.DS_Store' || f == '.AppleDouble'
         # build the zip command. cd to the order directory first so unzip will generate only a unit directory
         zip_cmd = "cd #{tmp_dir}; zip #{zip_file} #{File.join(unit.directory, File.basename(f))}"
         logger.info "Add to zip: #{zip_cmd}"
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

   def self.pdf_deliverable(unit, logger = Logger.new(STDOUT) )
      # Source tif files reside in 30_process_deliverables. Get the dir
      finalize_dir = File.join(Settings.production_mount, "finalization", unit.directory)
      tif_files = File.join(finalize_dir, "*.tif")

      # all of the scaled down JPEG source files will be pulled down into the
      # assemble deliverable directory; clean up prior versions
      logger.info "Setting up assemble delivery directory to be used to build the PDF..."
      assemble_dir = File.join(Settings.production_mount, "finalization", "tmp", unit.directory)
      pdf_file = File.join(assemble_dir, "#{unit.id}.pdf")
      if Dir.exist? assemble_dir
         if File.exist? pdf_file
            logger.info "Removing old deliverable from #{pdf_file}"
            FileUtils.rm(pdf_file)
         end
      else
         FileUtils.mkdir_p(assemble_dir)
      end

      # Convert all tifs in 30_process_deliverables into a single PDF
      logger.info "Covert #{tif_files} to scaled down JPG..."
      mogrify = `which mogrify`
      mogrify.strip!
      if !File.exist? mogrify
         fatal_error("mogrify command not found on system!")
      end
      cmd = "#{mogrify} -quiet -resize 1024x -density 150 -format jpg -path #{assemble_dir} #{tif_files}"
      logger.info("   #{cmd}")
      `#{cmd}`

      jpg_files = File.join(assemble_dir, "*.jpg")
      logger.info "Covert #{jpg_files} to #{pdf_file}..."
      cvt = `which convert`
      cvt.strip!
      if !File.exist? cvt
         fatal_error("convert command not found on system!")
      end
      cmd = "#{cvt} #{jpg_files} #{pdf_file}"
      logger.info("   #{cmd}")
      out = `#{cmd}`

      # See if it appears to have worked...
      if !out.strip.blank?
         raise "PDF generation failed: #{out}"
      end
      if !File.exist? pdf_file
         raise "Target PDF #{pdf_file} was not created"
      end

      # Zip the PDF into the delivery directory
      delivery_dir = File.join("#{DELIVERY_DIR}", "order_#{unit.order.id}")
      FileUtils.mkdir_p delivery_dir if !Dir.exist?(delivery_dir)
      zip_file = File.join(delivery_dir, "#{unit.id}.zip")
      logger.info("Zip PDF to #{zip_file}")
      if File.exist? zip_file
         File.delete zip_file
      end

      zip_cmd = "cd #{assemble_dir}; zip #{zip_file} #{unit.id}.pdf"
      logger.info "Zip PDF with: #{zip_cmd}"
      `#{zip_cmd}`
      logger.info "Zip deliverable of PDF created."
   end

   def self.create_deliverable(unit, master_file, source, dest_dir, call_number, location, logger = Logger.new(STDOUT) )
      order_id = unit.order_id
      master_file_id = master_file.id
      actual_res = master_file.image_tech_meta.resolution
      desired_res = unit.intended_use.deliverable_resolution
      add_legal_notice = false

      # Die if source is not tif or doesn't refer to a file
      if !(source.match(/\.tiff?$/) and File.file? source )
         raise "Source is not a .tif file: #{source}"
      end

      # Determine deliverable format and legal notice
      format = unit.intended_use.deliverable_format.strip
      if format.blank? or format =~ /^jpe?g$/i
         suffix = '.jpg'
         add_legal_notice = true
         use_id = unit.intended_use_id

         # New from Brandon; web publication and online exhibits don't need watermarks
         if unit.metadata.is_personal_item || unit.remove_watermark || use_id == 103 || use_id == 109
            add_legal_notice = false
            logger.info "Patron deliverable is a jpg file and will NOT a watermark"
            logger.info "One of the following is the reason:"
            logger.info "personal_item: #{unit.metadata.is_personal_item}, remove_watermark: #{unit.remove_watermark}, use_id: #{use_id} = 103/109"
         else
            logger.info "Patron deliverable is a jpg file and will have a watermark"
         end
      elsif format =~ /^tiff?$/i
         logger.info "Patron deliverable is a tif file and will NOT have a watermark"
         suffix = '.tif'
      else
         raise "Unexpected format value '#{format}'"
      end

      # format output path so it includes order number and unit number, like so: .../order123/54321/...
      dest_path = File.join(dest_dir, File.basename(source, '.*') + suffix)
      if File.exist? dest_path
         logger.info("Deliverable already exists at #{dest_path}")
         return dest_path
      end

      # Simple case; just a copy of tif at full resolution. No imagemagick needed
      if suffix == '.tif' && (desired_res.blank? or desired_res.to_s =~ /highest/i)
         FileUtils.cp(source, dest_path)
         return dest_path
      end

      # make changes to original image, if applicable
      MiniMagick.logger.level = Logger::DEBUG
      resample = nil
      convert = MiniMagick::Tool::Convert.new
      convert << "#{source}[0]"
      if desired_res.blank? or desired_res.to_s =~ /highest/i
         # keep original resolution
      elsif desired_res.to_i > 0
         if actual_res.blank?
            raise "actual_resolution is required when desired_resolution is specified"
         end
         # only downsize
         if actual_res > desired_res.to_i
            resample = desired_res.to_i
         end
      else
         raise "Unexpected desired_resolution value '#{desired_res}'"
      end

      if add_legal_notice
         #[0] -pointsize 100 -size 4000x -background lightgray -gravity center caption:"this is a\ntest" -gravity Center -append -bordercolor lightgray -border 50  cvt_drw.jpg
         logger.info "Adding legal notice"
         notice = ""
         if unit.metadata.title.length < 145
            notice << "Title: #{unit.metadata.title}\n"
         else
            notice << "Title: #{unit.metadata.title[0,145]}... \n"
         end

         if call_number
            notice << "Call Number: #{call_number}\n"
         end

         if location
            notice << "Location: #{location}\n\n"
         end

         # notice for personal research or presentation
         if unit.intended_use.id == 106 || unit.intended_use.id == 104
            logger.info "Notice of private study"
            notice << "This single copy was produced for the purposes of private study, scholarship, or research pursuant to 17 USC § 107 and/or 108.\nCopyright and other legal restrictions may apply to further uses. Special Collections, University of Virginia Library."
         elsif unit.intended_use.id == 100
            # Classroom instruction notice
            logger.info "Notice of classroom teaching"
            notice << "This single copy was produced for the purposes of classroom teaching pursuant to 17 USC § 107 (fair use).\nCopyright and other legal restrictions may apply to further uses. Special Collections, University of Virginia Library."
         end

         # image = MiniMagick::Image.open(source)
         cmd = "identify -quiet -ping -format '%w' #{source}[0]"
         width = `#{cmd}`.to_i
         sz = (width * 0.015).to_i
         sz = 22 if sz < 22

         # text size, center justify with colored background
         convert << "-bordercolor" << "lightgray" << "-border" << "0x10"
         convert << "-pointsize" << sz << "-size" << "#{width}x" << "-background" << "lightgray" << "-gravity" << "center"
         convert << "caption:#{notice}"

         # append the notoce to bottom center
         convert <<  "-gravity" << "Center" << "-append"

         # add a 20 border
         convert << "-bordercolor" << "lightgray" << "-border" << "30x20"
      end

      convert.resample(resample) if !resample.nil?
      convert << dest_path
      convert.call
      return dest_path
   end
end
