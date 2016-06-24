#encoding: utf-8

namespace :iiif do
   desc "Publish unit jp2 files to IIIF server"
   task :publish_unit  => :environment do
      id = ENV['id']
      u = Unit.find(id)
      src = File.join(Settings.archive_mount, id.rjust(9, "0") )
      puts "Src: #{src}"
      u.master_files.each do |mf|
         puts "create DL deliverable for MF #{mf.pid}"
         CreateDlDeliverables.exec_now({source: "#{src}/#{mf.filename}", master_file: mf})
      end
   end
end
