#encoding: utf-8

namespace :iiif do
   desc "Publish unit jp2 files to IIIF server"
   task :publish_unit  => :environment do
      id = ENV['id']
      u = Unit.find(id)
      src = File.join(Settings.archive_mount, id.rjust(9, "0") )
      puts "Src: #{src}"
      u.master_files.each do |mf|
         puts "Publish MF #{mf.pid} to IIIF server"
         PublishToIiif.exec_now({source: "#{src}/#{mf.filename}", master_file: mf})
      end
   end

   desc "Publish PATRON (non-DL) jp2 files to IIIF server"
   task :publish_patron  => :environment do
      puts "Publishing JP2 files to IIIF for units not in DL..."
      Unit.where("include_in_dl = ?",0).each do |u|
         cnt = 0
         src = File.join(Settings.archive_mount, u.id.to_s.rjust(9, "0") )
         puts "  Unit #{u.id} from #{src}..."
         u.master_files.each do |mf|
            begin
               PublishToIiif.exec_now({source: "#{src}/#{mf.filename}", master_file: mf})
               cnt += 1
            rescue Exception=>e
               puts "    * Master File #{mf.id} FAILED: #{e.to_s}"
            end
         end
         puts "    published #{cnt} images to IIIF"
         raise "stop"
      end
   end
end
