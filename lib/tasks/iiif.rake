#encoding: utf-8
require 'tempfile'
require "rmagick"

namespace :iiif do
   desc "Publish jp2 files to IIIF server"
   task :publish_all  => :environment do
      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      raise "KDU_COMPRESS not found" if !File.exist?(kdu)

      puts "Use #{kdu} to generate JP2K from #{Settings.archive_mount} in #{Settings.iiif_mount}..."
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
               `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
            end
         end
      end
   end

   desc "Publish UNIT jp2 files to IIIF server"
   task :publish_unit  => :environment do
      unit_id = ENV['id']
      raise "id is required" if unit_id.blank?
      unit = Unit.find(unit_id)
      overwrite = ENV['overwrite'] == "1"
      puts "Overwrite? #{overwrite}"

      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      raise "KDU_COMPRESS not found" if !File.exist?(kdu)

      puts "Use #{kdu} to generate JP2K from #{Settings.archive_mount} in #{Settings.iiif_mount}..."
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
               temp_file = nil
               tiff = Magick::Image.read(source).first
               unless tiff.compression.to_s == "NoCompression"
                   temp_file = Tempfile.new([mf.filename.split(".")[0], ".tif"] )
                   puts "writing uncompresed tif to #{temp_file.path}"
                   cmd = "convert -quiet #{source} -compress None #{temp_file.path}"
                   `#{cmd}`
                   source = temp_file.path
               end
               tiff.destroy!

               `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
               temp_file.unlink if !temp_file.nil?
            end
         end
      end
   end

   desc "Republish MF with size > 524000000 using a different set of KDU params"
   task :republish_large  => :environment do
      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      raise "KDU_COMPRESS not found" if !File.exist?(kdu)
      abort("BAD HANDLINNG OF COMPRESSED FILES")

      puts "Use #{kdu} to generate JP2K from #{Settings.archive_mount} in #{Settings.iiif_mount}..."
      MasterFile.where("filesize > 524000000").find_each do |mf|
         if mf.pid.blank?
            puts "ERROR: MasterFile #{mf.id} has no PID. Skipping."
            next
         end

         jp2k_path = iiif_path(mf.pid)
         source = File.join(Settings.archive_mount, mf.unit.id.to_s.rjust(9, "0"), mf.filename )
         if File.exists?(source) == false
             puts "ERROR: source not found: #{source}"
         else
            puts "#{mf.pid}: Generate JP2K from #{source} to #{jp2k_path}"
            jp2k_dir = File.dirname(jp2k_path)
            FileUtils.mkdir_p jp2k_dir if !Dir.exist?(jp2k_dir)

            # only supports uncompressed...
            tiff = Magick::Image.read(source).first
            unless tiff.compression.to_s == "NoCompression"
                source = "#{Rails.root}/tmp/tiffs/#{mf.filename}"
                puts "writing uncompresed tif #{source}"
                tiff.compression=Magick::CompressionType.new("NoCompression", 1)
                tiff.write(source)
            end
            tiff.destroy!

            `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
         end
      end
   end

   desc "REPUBLISH BAD MASTER FILES"
   task :republish_bad  => :environment do

      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip
      raise "KDU_COMPRESS not found" if !File.exist?(kdu)

      puts "Use #{kdu} to generate JP2K from #{Settings.archive_mount} in #{Settings.iiif_mount}..."
      File.open(File.join(Rails.root, ENV['file']), "r").each_line do |pid|
         pid.strip!
         mf = MasterFile.find_by(pid: pid)
         abort("#{pid} not found!") if mf.nil?

         # If there is a non-zero length jp2 already present, skip
         jp2k_path = iiif_path(mf.pid)
         if File.exists?(jp2k_path) && File.size(jp2k_path) > 0
            puts "Skipping non-zero length #{jp2k_path}"
            next
         end

         source = File.join(Settings.archive_mount, mf.unit.id.to_s.rjust(9, "0"), mf.filename )
         if File.exists?(source) == false
             puts "ERROR: source not found: #{source}"
         else
            puts "Generate JP2K from #{source} to #{jp2k_path}"
            jp2k_dir = File.dirname(jp2k_path)
            FileUtils.mkdir_p jp2k_dir if !Dir.exist?(jp2k_dir)

            # attempt to read in the tif. If the file is messed up
            # the read will raise an exception. Log the bad file and skip it
            tiff = nil
            temp_file = nil
            begin
               tiff = Magick::Image.read(source).first
            rescue Exception => e
               puts "ERROR reading #{source}: #{e}"
               next
            end

            # Good file. Make sure it is not compressed
            unless tiff.compression.to_s == "NoCompression"
                temp_file = Tempfile.new([mf.filename.split(".")[0], ".tif"] )
                puts "writing uncompresed tif to #{temp_file.path}"
                cmd = "convert -quiet #{source} -compress None #{temp_file.path}"
                `#{cmd}`
                source = temp_file.path
            end
            tiff.destroy!

            `#{kdu} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
            temp_file.unlink if !temp_file.nil?
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
