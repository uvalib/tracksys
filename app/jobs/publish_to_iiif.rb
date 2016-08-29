class PublishToIiif < BaseJob

   require 'rmagick'
   require 'fileutils'

   def do_workflow(message)

      raise "Parameter 'source' is required" if message[:source].blank?
      raise "Parameter 'master_file_id' is required" if message[:master_file_id].blank?

      source = message[:source]
      master_file = MasterFile.find(message[:master_file_id])

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

      # set path to IIIF jp2k storage location
      pid_parts = master_file.pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/../) # break up into 2 digit sections, but this leaves off last char if odd
      parts << base.last if parts.length * 2 !=  base.length
      pid_dirs = parts.join("/")
      jp2k_filename = "#{base}.jp2"
      jp2k_path = File.join(Settings.iiif_mount, pid_parts[0], pid_dirs)
      FileUtils.mkdir_p jp2k_path if !Dir.exist?(jp2k_path)
      jp2k_path = File.join(jp2k_path, jp2k_filename)

      if master_file.filename.match(".jp2$")
         # write a JPEG-2000 file to the destination directory
         FileUtils.copy(source, jp2k_path)
         on_success "Copied JPEG-2000 image using '#{source}' as input file for the creation of deliverable '#{jp2k_path}'"

      elsif source.match(/\.tiff?$/) and File.file?(source)
         # If the JP2k already exists (and is not 0), don't make it again!
         if File.exist?(jp2k_path) && File.size(jp2k_path) > 0
            logger.info "MasterFile #{master_file.id} already has JP2k file at #{jp2k_path}; skipping creation"
            return
         end

         # Directly invoke Ruby's garbage collection to clear memory
         GC.start

         # generate deliverables for DL use
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
      else
         raise "Source is not a .tif file: #{source}"
      end
   end
end
