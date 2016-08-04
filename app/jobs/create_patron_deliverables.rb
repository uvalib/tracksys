class CreatePatronDeliverables < BaseJob

   require 'rubygems'
   require 'rmagick'
   require 'digest/md5'

   # Message can have these keys:
   # * source - full path to the source image file (master TIFF) to be
   #   processed
   # * format - "jpeg" or "tiff" (only applies when mode is "patron" or "both";
   #   defaults to "jpeg")
   # * unit_id (only applies when mode is "patron" or "both")
   # * actual_resolution - resolution of master file (only applies when mode is
   #   "patron" or "both")
   # * desired_resolution - resolution requested by customer for deliverables
   #   (only applies when mode is "patron" or "both"; defaults to highest
   #   possible)
   # * remove_watermark - This option, set at the unit level, allows staff to
   #   to disable the inclusion of a watermark for the entire unit if the
   #   deliverable format is JPEG.
   #
   # Watermark Additions -
   # The following are n required and will only be used if format == 'jpeg'.
   # * call_number - If the item gets a watermark, this value will be added to the notice
   # * title - If the item gets a watermark, this value will be added to the notice.
   # * location - If the item gets a watermark, this value will be added to the notice.
   # * personal_item - If this is true, the watermark doesn't get written at all
   #
   # Most of these keys are optional, because there are reasonable defaults,
   # but "source" is always required; "pid" is required if mode is "dl", "dl-archive" or
   # "both"; order and unit numbers are required if mode is "patron" or "both".

   def do_workflow(message)

      raise "Parameter 'source' is required" if message[:source].blank?
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'master_file_id' is required" if message[:master_file_id].blank?

      source = message[:source]
      master_file_id = message[:master_file_id]
      desired_res = message[:desired_resolution]

      # In order to construct the directory for deliverables, this processor must know the order_id
      order_id = Unit.find(message[:unit_id]).order.id

      if source.match(/\.tiff?$/) and File.file?(source)
         format = message[:format].to_s.strip
         if format.blank? or format =~ /^jpe?g$/i
            suffix = '.jpg'
            add_legal_notice = true
            if message[:personal_item] || message[:remove_watermark]
               add_legal_notice = false
            end
         elsif format =~ /^tiff?$/i
            suffix = '.tif'
            add_legal_notice = false
         else
            raise "Unexpected format value '#{message[:format]}'"
         end

         # format output path so it includes order number and unit number, like so: .../order123/54321/...
         dest_dir = File.join(ASSEMBLE_DELIVERY_DIR, 'order_' + order_id.to_i.to_s, message[:unit_id].to_i.to_s)
         FileUtils.mkdir_p(dest_dir)
         dest_path = File.join(dest_dir, File.basename(source, '.*') + suffix)

         # Simple case; just a copy of tif at full resolution. No imagemagick needed
         if suffix == '.tif' && (desired_res.blank? or desired_res.to_s =~ /highest/i)
            FileUtils.cp(source, dest_path)
            on_success "Deliverable image for MasterFile #{master_file_id}."
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
            if message[:actual_resolution].blank?
               raise "actual_resolution is required when desired_resolution is specified"
            end
            # only downsize
            if message[:actual_resolution].to_i > desired_res.to_i
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

            notice << "Under 17USC, Section 107, this single copy was produced for the purposes of private study, scholarship, or research.\nNo further copies should be made. Copyright and other legal restrictions may apply. Special Collections, University of Virginia Library."

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

         on_success "Deliverable image for MasterFile #{master_file_id}."
      else
         raise "Source is not a .tif file: #{source}"
      end
   end
end
