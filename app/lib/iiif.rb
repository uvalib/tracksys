module IIIF
   def self.publish(source, master_file, overwrite, logger = Logger.new(STDOUT))
      # Generate a checksum if one does not already exist
      if master_file.md5.nil?
         source_md5 = Digest::MD5.hexdigest(File.read(source))
         master_file.update(md5: source_md5)
      end

      if master_file.filename.match(".tif$")
         # kakadu cant handle compression. remove it if detected
         cmd = "identify -quiet -ping -format '%C' #{source}[0]"
         compression = `#{cmd}`
         if compression != 'None'
            cmd = "convert -compress none -quiet #{source} #{source}"
            `#{cmd}`
            logger.info "MasterFile #{master_file.id} is compressed. This has been corrected automatically."
         end
      end

      # set path to IIIF jp2k storage location
      jp2k_path = master_file.iiif_file()
      jp2kdir = File.dirname(jp2k_path)
      if !Dir.exist?(jp2kdir)
         logger.info "IIIF destination #{jp2kdir} does not exist; creating"
         FileUtils.mkdir_p jp2kdir
      else
         logger.info "IIIF destination #{jp2kdir} already exists"
      end

      if master_file.filename.match(".jp2$")
         FileUtils.copy(source, jp2k_path)
         logger.info "Copied JPEG-2000 image using '#{source}' as input file for the creation of deliverable '#{jp2k_path}'"

      elsif source.match(/\.tiff?$/) and File.file?(source)
         # If the JP2k already exists (and is not 0), don't make it again!
         if overwrite == false && File.exist?(jp2k_path) && File.size(jp2k_path) > 0
            logger.info "MasterFile #{master_file.id} already has JP2k file at #{jp2k_path}; skipping creation"
            return
         end

         executable = KDU_COMPRESS || %x( which kdu_compress ).strip
         if File.exist? executable
            logger.debug("Compressing #{source} to #{jp2k_path}...")
            cmd = "#{executable} -i #{source} -o #{jp2k_path} -rate 0.5 Clayers=1 Clevels=7"
            cmd << " \"Cprecincts={256,256},{256,256},{256,256},{128,128},{128,128},{64,64},{64,64},{32,32},{16,16}\""
            cmd << " \"Corder=RPCL\" \"ORGgen_plt=yes\" \"ORGtparts=R\" \"Cblk={64,64}\""
            cmd << " Cuse_sop=yes -quiet -num_threads 8"
            `#{cmd}`
            logger.debug("...compression complete")
            if !File.exist?(jp2k_path) || File.size(jp2k_path) == 0
               raise "Destination #{jp2k_path} does not exist or is zero length"
            end
         else
            convert = "/usr/local/bin/convert"
            if !File.exist? convert
               convert = %x( which convert ).strip
            end
            logger.warn("#{executable} not found, using #{convert} instead")
            `#{convert} #{source} -quiet -compress JPEG2000 -quality 75 -define jp2:rate=1.5 #{jp2k_path}`
         end

         logger.info "Generated JPEG-2000 image using '#{source}' as input file for the creation of deliverable '#{jp2k_path}'"
      else
         raise "Source is not a .tif or .jp2 file: #{source}"
      end
   end
end
