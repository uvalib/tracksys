#encoding: utf-8

namespace :iiif do
   desc "Publish unit jp2 files to IIIF server"
   task :publish_all  => :environment do
      iiif_mount = ENV['iiif_mount']
      raise "iiif_mount is required" if iiif_mount.blank?
      archive_mount = ENV['archive_mount']
      raise "archive_mount is required" if archive_mount.blank?

      kdu = KDU_COMPRESS || %x( which kdu_compress ).strip

      puts "Use #{kdu} to generate JP2K file all master files in #{iiif_mount}..."
      MasterFile.find_each do |mf|
         jp2k_path = iiif_path(mf.pid)
         if File.exists?(jp2k_path) == false
            source = File.join(Settings.archive_mount, mf.unit.id.to_s.rjust(9, "0"), mf.filename )
            puts "Generate JP2K from #{src}"
            if mf.filesize > 524000000
               `#{executable} -i #{source} -o #{jp2k_path} -rate 1.5 Clayers=20 Creversible=yes Clevels=8 Cprecincts="{256,256},{256,256},{128,128}" Corder=RPCL ORGgen_plt=yes ORGtparts=R Cblk="{32,32}" -num_threads #{NUM_JP2K_THREADS}`
            else
               `#{executable} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads 2`
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

   # desc "Publish unit jp2 files to IIIF server"
   # task :publish_unit  => :environment do
   #    id = ENV['id']
   #    u = Unit.find(id)
   #    src = File.join(Settings.archive_mount, id.rjust(9, "0") )
   #    puts "Src: #{src}"
   #    u.master_files.each do |mf|
   #       puts "Publish MF #{mf.pid} to IIIF server"
   #       PublishToIiif.exec_now({source: "#{src}/#{mf.filename}", master_file_id: mf.id})
   #    end
   # end
   #
   # desc "Publish PATRON (non-DL) jp2 files to IIIF server"
   # task :publish_patron  => :environment do
   #    puts "Publishing JP2 files to IIIF for units not in DL..."
   #    Unit.where("include_in_dl = ?",0).each do |u|
   #       cnt = 0
   #       src = File.join(Settings.archive_mount, u.id.to_s.rjust(9, "0") )
   #       puts "  Unit #{u.id} from #{src}..."
   #       u.master_files.each do |mf|
   #          begin
   #             PublishToIiif.exec_now({source: "#{src}/#{mf.filename}", master_file_id: mf.id})
   #             cnt += 1
   #          rescue Exception=>e
   #             puts "    * Master File #{mf.id} FAILED: #{e.to_s}"
   #          end
   #       end
   #       puts "    published #{cnt} images to IIIF"
   #       raise "stop"
   #    end
   # end
end
