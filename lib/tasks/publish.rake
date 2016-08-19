namespace :publish do
   desc "Republish each item identified by the pids listed in the given file."
   task :republish_failed_pids  => :environment do
      if ENV['file'].nil?
         abort "You must specify a file containing the failed pids.  Example: rake publish:republish_failed_pids file=failed-pids.txt"
      end

      File.foreach(ENV['file'])  do |pid|
        pid = pid.strip
        if !pid.empty?
            object = Bibl.find_by(pid: pid)
            type = "bibl"
            if object.nil?
                object = MasterFile.find_by(pid: pid)
                type = "master file"
            end
            if object.nil?
                abort("Specified pid #{pid} was not found as a bibl or master file!")
            else
                if object[:date_dl_update].nil? || object[:date_dl_ingest].nil?
                  puts "Skipping #{type} #{object.id} because it hasn't been published."
                else
                  puts "Updating date_dl_update for #{type} #{object.id} from #{object[:date_dl_update]} to now."
                  object.update_attribute(:date_dl_update, Time.now)
                end
            end
        end
      end
   end
end
