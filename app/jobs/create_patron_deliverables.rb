class CreatePatronDeliverables < BaseJob

   require 'rubygems'
   require 'rmagick'
   require 'digest/md5'

   def do_workflow(message)

      raise "Parameter 'source' is required" if message[:source].blank?
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'master_file' is required" if message[:master_file].blank?

      source = message[:source]
      unit = message[:unit]
      order_id = unit.order_id
      master_file_id = message[:master_file].id
      actual_res = message[:master_file].image_tech_meta.resolution
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
         if message[:personal_item] || unit.remove_watermark || use_id == 103 || use_id == 109
            add_legal_notice = false
         end
      elsif format =~ /^tiff?$/i
         suffix = '.tif'
      else
         raise "Unexpected format value '#{format}'"
      end

      # format output path so it includes order number and unit number, like so: .../order123/54321/...
      dest_dir = File.join(ASSEMBLE_DELIVERY_DIR, "order_#{order_id}", unit.id.to_s)
      FileUtils.mkdir_p(dest_dir)
      dest_path = File.join(dest_dir, File.basename(source, '.*') + suffix)

      # Simple case; just a copy of tif at full resolution. No imagemagick needed
      if suffix == '.tif' && (desired_res.blank? or desired_res.to_s =~ /highest/i)
         FileUtils.cp(source, dest_path)
         on_success "Deliverable image for MasterFile #{master_file_id} at #{dest_path}."
         return
      end

      tiff = Magick::Image.read(source).first

      # Directly invoke Ruby's garbage collection to clear memory
      GC.start

      # make changes to original image, if applicable
      new_tiff = nil
      if desired_res.blank? or desired_res.to_s =~ /highest/i
         # keep original resolution
         logger.info("Keeping original resolution")
      elsif desired_res.to_i > 0
         if actual_res.blank?
            raise "actual_resolution is required when desired_resolution is specified"
         end
         # only downsize
         if actual_res > desired_res.to_i
            logger().debug("Resampling image...")
            new_tiff = tiff.resample(desired_res.to_i)
         end
      else
         raise "Unexpected desired_resolution value '#{desired_res}'"
      end

      if add_legal_notice
         logger().debug "Add legal notice"
         notice = String.new

         if message[:title].length < 145
            notice << "Title: #{message[:title]}\n"
         else
            notice << "Title: #{message[:title][0,145]}... \n"
         end

         if message[:call_number]
            notice << "Call Number: #{message[:call_number]}\n"
         end

         if message[:location]
            notice << "Location: #{message[:location]}\n\n"
         end

         # notice for personal research or presentation
         if unit.intended_use.id == 106 || unit.intended_use.id == 104
            notice << "This single copy was produced for the purposes of private study, scholarship, or research pursuant to 17 USC § 107 and/or 108.\nCopyright and other legal restrictions may apply to further uses. Special Collections, University of Virginia Library."
         elsif unit.intended_use.id == 100
            # Classroom instruction notice
            notice << "This single copy was produced for the purposes of classroom teaching pursuant to 17 USC § 107 (fair use).\nCopyright and other legal restrictions may apply to further uses. Special Collections, University of Virginia Library."
         end

         # determine point size to use, relative to image width in pixels
         point_size = (tiff.columns * 0.014).to_i  # arrived at this by trial and error; not sure why it works, but it works

         # determine height of bottom border (to contain six lines of text at that point size)
         bottom_border_height = (point_size * 6).to_i  # again, arrived at this by trial and error

         # add border (20 pixels left and right, bottom_border_height pixels top and bottom)
         bordered = tiff.border(20, bottom_border_height, 'lightgray')

         # add text within bottom border
         draw = Magick::Draw.new
         draw.font_family = 'times'
         draw.pointsize = point_size
         draw.gravity = Magick::SouthGravity
         draw.annotate(bordered,0,0,5,5,notice)

         if bottom_border_height < 100
            # Skip the writing of a watermarked new_tif because the watermark would be too small to read
         else
            # crop to reduce top border to 20 pixels
            new_tiff = bordered.crop(Magick::SouthGravity, bordered.columns, bordered.rows - (bottom_border_height - 20))
         end
      end

      new_tiff = tiff if new_tiff.nil?

      # write output file
      new_tiff.write(dest_path)

      # Invoke Rmagick destroy! method to clear memory of legacy image information
      new_tiff.destroy!
      tiff.destroy!

      on_success "Deliverable image for MasterFile #{master_file_id} at #{dest_path}."
   end
end
