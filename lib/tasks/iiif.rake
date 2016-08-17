#encoding: utf-8

namespace :iiif do
   desc "Publish jp2 files to IIIF server"
   task :publish_all  => :environment do
      iiif_mount = ENV['iiif_mount']
      raise "iiif_mount is required" if iiif_mount.blank?
      archive_mount = ENV['archive_mount']
      raise "archive_mount is required" if archive_mount.blank?

      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      raise "KDU_COMPRESS not found" if !File.exist?(kdu)

      puts "Use #{kdu} to generate JP2K from #{archive_mount} in #{iiif_mount}..."
      MasterFile.find_each do |mf|
         if mf.pid.blank?
            puts "ERROR: MasterFile #{mf.id} has no PID. Skipping."
            next
         end

         jp2k_path = iiif_path(mf.pid)
         if File.exists?(jp2k_path) == false
            source = File.join(Settings.archive_mount, mf.unit.id.to_s.rjust(9, "0"), mf.filename )
            if File.exists?(source) == false
                puts "ERROR: source not found: #{source}"
            else
               puts "Generate JP2K from #{source}"
               jp2k_dir = File.dirname(jp2k_path)
               FileUtils.mkdir_p jp2k_dir if !Dir.exist?(jp2k_dir)
               if !mf.filesize.blank? && mf.filesize > 524000000
                  `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.5 Clayers=20 Creversible=yes Clevels=8 Cprecincts="{256,256},{256,256},{128,128}" Corder=RPCL ORGgen_plt=yes ORGtparts=R Cblk="{32,32}" -num_threads 2`
               else
                  `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
               end
            end
         end
      end
   end

   desc "Publish UNIT jp2 files to IIIF server"
   task :publish_unit  => :environment do
      iiif_mount = ENV['iiif_mount']
      raise "iiif_mount is required" if iiif_mount.blank?
      archive_mount = ENV['archive_mount']
      raise "archive_mount is required" if archive_mount.blank?
      unit_id = ENV['id']
      raise "id is required" if unit_id.blank?
      unit = Unit.find(unit_id)
      overwrite = ENV['overwrite'] == "1"
      puts "Overwrite? #{overwrite}"

      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      raise "KDU_COMPRESS not found" if !File.exist?(kdu)

      puts "Use #{kdu} to generate JP2K from #{archive_mount} in #{iiif_mount}..."
      unit.master_files.each do |mf|
         if mf.pid.blank?
            puts "ERROR: MasterFile #{mf.id} has no PID. Skipping."
            next
         end

         jp2k_path = iiif_path(mf.pid)
         if File.exists?(jp2k_path) == false || overwrite == true
            source = File.join(Settings.archive_mount, mf.unit.id.to_s.rjust(9, "0"), mf.filename )
            if File.exists?(source) == false
                puts "ERROR: source not found: #{source}"
            else
               puts "Generate JP2K from #{source} to #{jp2k_path}"
               jp2k_dir = File.dirname(jp2k_path)
               FileUtils.mkdir_p jp2k_dir if !Dir.exist?(jp2k_dir)

               # only supports uncompressed...
               tiff = Magick::Image.read(source).first
               unless tiff.compression.to_s == "NoCompression"
                   source = "#{Rails.root}/tmp/tiffs/#{mf.filename}"
                   puts "wrinting uncompresed tif #{source}"
                   tiff.compression=Magick::CompressionType.new("NoCompression", 1)
                   tiff.write(source)
               end
               tiff.destroy!

               if !mf.filesize.blank? && mf.filesize > 524000000
                  `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.5 Clayers=20 Creversible=yes Clevels=8 Cprecincts="{256,256},{256,256},{128,128}" Corder=RPCL ORGgen_plt=yes ORGtparts=R Cblk="{32,32}" -num_threads 2`
               else
                  `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
               end
            end
         end
      end
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
