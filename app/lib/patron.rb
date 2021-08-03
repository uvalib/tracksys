module Patron
   # Create patron deliverable and return the full path to the file
   #
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
