namespace :masterfile do
   desc "Replace all masterfiles/technical metadata for a unit"
   task :replace_all  => :environment do
      id = ENV['id']
      abort("id is required") if id.blank?
      unit = Unit.find_by(id: id)
      abort("Invalid ID") if unit.nil?

      # Setup get src dir and ensure that archive dir exists
      unit_dir = "%09d" % unit.id
      src_dir = File.join(IN_PROCESS_DIR, unit_dir)
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      if !Dir.exist? archive_dir
         FileUtils.makedirs(archive_dir)
         FileUtils.chmod(0775, File.join(ARCHIVE_DIR, f))
      end

      puts "Replacing master files for unit #{id} with content from #{src_dir}..."

      # read in the iview XML and walk the MediaItems
      doc = Nokogiri.XML( File.open(File.join(IN_PROCESS_DIR, unit_dir, "#{unit_dir}.xml")))
      doc.root.xpath('//MediaItemList/MediaItem').each do |item|
         # Get the master file with matching filename
         fn = item.xpath("AssetProperties/Filename").text
         mf = unit.master_files.find_by(filename: fn)
         if mf.nil?
            puts "ERROR: Unable to find existing master file with filename: #{fn}"
            next
         end

         # Update the tech metadata
         puts "Updating masterfile #{mf.id}: #{mf.filename}"
         puts "   Updating tech metadata"
         ImportIviewXml.update_tech_meta(item, mf.image_tech_meta)

         # Update MD5 hash
         puts "   Update MD5 hash"
         tif_path = File.join(src_dir, fn)
         mf.update(updated_at: Time.now, md5: Digest::MD5.hexdigest(File.read("#{tif_path}")))

         # Re-publish to IIIF
         puts "   Publishing to IIIF"
         publish_to_iiif(mf, tif_path)

         # Re-Archive
         arch_file = File.join(archive_dir, fn)
         puts "   Archiving to #{arch_file}"
         FileUtils.copy(tif_path, arch_file)
         FileUtils.chmod(0664, arch_file)
         arch_md5 = Digest::MD5.hexdigest(File.read("#{arch_file}"))
         if arch_md5 != mf.md5
            puts "   WARN #{arch_file} failed checksum test"
         end
      end

      # Lastly, send the catalog and iview XML to the archive
      puts "Archiving IViewXML and mpcatalog"
      FileUtils.copy(File.join(src_dir, "#{unit_dir}.xml"), File.join(archive_dir, "#{unit_dir}.xml"))
      FileUtils.chmod(0664, File.join(archive_dir, "#{unit_dir}.xml"))
      FileUtils.copy(File.join(src_dir, "#{unit_dir}.mpcatalog"), File.join(archive_dir, "#{unit_dir}.mpcatalog"))
      FileUtils.chmod(0664, File.join(archive_dir, "#{unit_dir}.mpcatalog"))
      puts "DONE"
   end

   def publish_to_iiif(mf, source_tif)
      # get dettination path
      jp2k_path = iiif_path(mf.pid)
      puts "   IIIF destination: #{jp2k_path}"

      # Make sure tiff is not compressed
      tiff = nil
      temp_file = nil
      begin
         tiff = Magick::Image.read(source_tif).first
      rescue Exception => e
         puts "ERROR reading #{source_tif}: #{e}"
         return
      end
      unless tiff.compression.to_s == "NoCompression"
          temp_file = Tempfile.new([mf.filename.split(".")[0], ".tif"] )
          puts "   writing uncompresed tif to #{temp_file.path}"
          cmd = "convert -quiet #{source} -compress None #{temp_file.path}"
          `#{cmd}`
          source_tif = temp_file.path
      end
      tiff.destroy!

      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      if !File.exist?(kdu)
         puts "   Missing KDU can't generate JP2K file"
      else
         `#{kdu} -i #{source_tif} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
      end
      temp_file.unlink if !temp_file.nil?
   end

   def iiif_path(pid)
      pid_parts = pid.split(":")
      base = pid_parts[1]
      parts = base.scan(/../) # break up into 2 digit sections, but this leaves off last char if odd
      parts << base.last if parts.length * 2 !=  base.length
      pid_dirs = parts.join("/")
      jp2k_filename = "#{base}.jp2"
      jp2k_path = File.join(Settings.iiif_mount, pid_parts[0], pid_dirs)
      FileUtils.mkdir_p jp2k_path if !Dir.exist?(jp2k_path)
      jp2k_path = File.join(jp2k_path, jp2k_filename)
      return jp2k_path
   end
end
