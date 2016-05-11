class CreateDlDeliverables < BaseJob

   require 'rubygems'
   require 'rmagick'

   # Message can have these keys:
   # * pid - pid of the source image file
   # * source - full path to the source image file (master TIFF) to be
   #   processed
   # * mode - "dl", "dl-archive", "patron" or "both"
   # * format - "jpeg" or "tiff" (only applies when mode is "patron" or "both";
   #   defaults to "jpeg")
   # * order_id (only applies when mode is "patron" or "both")
   # * unit_id (only applies when mode is "patron" or "both")
   # * actual_resolution - resolution of master file (only applies when mode is
   #   "patron" or "both")
   # * desired_resolution - resolution requested by customer for deliverables
   #   (only applies when mode is "patron" or "both"; defaults to highest
   #   possible)
   # * last - If the master file is the last one for a unit, then this processor
   #   will send a message to the archive processor to archive the unit.
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
      raise "Parameter 'master_file' is required" if message[:master_file].blank?

      source = message[:source]
      last = message[:last]
      master_file = message[:master_file]

      # Given the new requirment of recording md5 for MasterFile objects and the prohibition on downloading everything from
      # tape to record those md5's, we will take the opportunity here to record them as we pull them down from Stornext.
      #
      # Only do this if the md5 is empty and respect the old value.
      if master_file.md5.nil?
         source_md5 = Digest::MD5.hexdigest(File.read(source))
         master_file.update_attributes(:md5 => source_md5)
      end

      if master_file.filename.match(".tif$")
         # Introduce error handling for uncompressed images that kakadu will choke on.
         tiff = Magick::Image.read(source).first
         filesize = tiff.filesize
         unless tiff.compression.to_s == "NoCompression"
            tiff.compression=Magick::CompressionType.new("NoCompression", 1)
            tiff.write(source)
            tiff.destroy!
            on_success "MasterFile #{master_file.id} is compressed.  This has been corrected automatically.  Update MD5 for #{source} if necessary."
         end

         tiff.destroy!
      end

      if master_file.filename.match(".jp2$")
         # write a JPEG-2000 file to the destination directory
         jp2k_filename = master_file.pid.sub(/:/, '_') + '.jp2'
         jp2k_path = File.join(BASE_DESTINATION_PATH_DL, jp2k_filename)
         FileUtils.copy(source, jp2k_path)

         # send message to tracksys ingest_jp2k_processor (so it can add jp2 deliverable as datastream for this object)
         IngestJp2k.exec_now( { :master_file=> master_file, :jp2k_path => jp2k_path, :source => source }, self )
         on_success "Copied JPEG-2000 image using '#{source}' as input file for the creation of deliverable '#{jp2k_path}'"

      elsif source.match(/\.tiff?$/) and File.file?(source)
         # Directly invoke Ruby's garbage collection to clear memory
         GC.start

         # generate deliverables for DL use
         # write a JPEG-2000 file to the destination directory
         jp2k_filename = master_file.pid.sub(/:/, '_') + '.jp2'
         jp2k_path = File.join(BASE_DESTINATION_PATH_DL, jp2k_filename)

         # As per a conversation with Ethan Gruber, I'm dividing the JP2K compression ratios between images that are greater and less than 500MB.
         executable = KDU_COMPRESS || %x( which kdu_compress ).strip
         if File.exist? executable
            logger().debug("Compressing #{source} to #{jp2k_path}...")
            if filesize > 524000000
               `#{executable} -i #{source} -o #{jp2k_path} -rate 1.5 Clayers=20 Creversible=yes Clevels=8 Cprecincts="{256,256},{256,256},{128,128}" Corder=RPCL ORGgen_plt=yes ORGtparts=R Cblk="{32,32}" -num_threads #{NUM_JP2K_THREADS}`
            else
               `#{executable} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads #{NUM_JP2K_THREADS}`
            end
            logger().debug("...compression complete")
         else
            logger().warn("#{executable} not found, using ImageMagick instead")
            `/usr/local/bin/convert #{source} -quiet -compress JPEG2000 -quality 75 -define jp2:rate=1.5 #{jp2k_path}`
         end

         # send message to tracksys ingest_jp2k_processor (so it can add jp2 deliverable as datastream for this object)
         on_success "Generated JPEG-2000 image using '#{source}' as input file for the creation of deliverable '#{jp2k_path}'"
         IngestJp2k.exec_now( { :master_file=>master_file, :jp2k_path => jp2k_path, :source => source }, self )
      else
         raise "Source is not a .tif file: #{source}"
      end

      if last.to_i == 1
         unit_id = master_file.unit.id
         logger().info("Last JP2K for Unit #{unit_id} created.")
         master_file.unit.update_attribute(:date_dl_deliverables_ready, Time.now)

         SendCommitToSolr.exec_now({}, self)

         on_success "Unit #{unit_id} has completed ingestion to #{FEDORA_REST_URL}."

         if source.match("#{FINALIZATION_DIR_MIGRATION}") or source.match("#{FINALIZATION_DIR_PRODUCTION}")
            logger().debug("Removing processing directory #{source}/...")
            FileUtils.rm_rf(del_dir)
            logger.info("Files for unit #{unit_id} copied for the creation of #{@dl} deliverables have now been deleted.")
         end
      end
   end
end
