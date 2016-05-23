require 'fileutils'

namespace :rights do

   desc "initialize all bibls to CNE"
   task :init_cne  => :environment do
      cne = UseRight.find_by(name: "Copyright Not Evaluated")
      puts "Update all bibls with no right statement to #{cne.name}..."
      ActiveRecord::Base.connection.execute("update bibls set use_right_id=#{cne.id} where use_right_id is null")
      puts "DONE"
   end

   desc "initialize all MASTER FILES to CNE"
   task :init_mf_cne  => :environment do
      cne = UseRight.find_by(name: "Copyright Not Evaluated")
      puts "Update all master_files with no right statement to #{cne.name}..."
      ActiveRecord::Base.connection.execute("update master_files set use_right_id=#{cne.id} where use_right_id is null")
      puts "DONE"
   end

   desc "Mark all MF that are manuscripts and in virgo as NKC"
   task :nkc_mf  => :environment do
      nkc = UseRight.find_by(name: "No Known Copyright")
      puts "Update MF belonging to NKC Bibl to be NKC..."
      Bibl.where("use_right_id=#{nkc.id}").find_each do |bibl|
         bibl.master_files.update_all(use_right_id: nkc.id)
      end

      puts "Update manuscript MF that are in digital Library as NKC..."
      Bibl.where('is_manuscript=1').where.not(date_dl_ingest: nil).find_each do |ms|
         ms.master_files.update_all(use_right_id: nkc.id)
      end
   end

   desc "Mark all pre-1923 content as NKC"
   task :nkc  => :environment do
      nkc = UseRight.find_by(name: "No Known Copyright")

      # hierarchical collection PIDs. These will be skipped
      # daily progress, Our Mountain Work in the Dioces of Virginia, Our Mountain Work
      # Corks and Curls, Walter Reed Yellow Fever Collection, Dr. Henry Thomas Skinner Papers
      # NOTE: these PIDs are COMPONENT PID for the top-level component in the hierarchy
      skip = ["uva-lib:2137307", "uva-lib:2253857", "uva-lib:2528441", "uva-lib:2250968", "uva-lib:2513789", "uva-lib:1330419"]

      progress_logfile = "log/rights.log"
      progress_log = Logger.new(progress_logfile)
      progress_log.formatter = proc do |severity, datetime, progname, msg|
         "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{severity} : #{msg}\n"
      end

      # check bibls with year data (this year field is extracted from the MARC 260c)
      puts "start processing..."
      progress_log.info "Checking all bibl records with a barcode..."
      Bibl.where.not(barcode: nil).find_each do |bibl|
         # Skip hierarchical collections:
         if bibl.components?
            top_component = bibl.components.first
            next if skip.include? top_component.pid
         end

         progress_log.info "Get MARC year for barcode #{bibl.barcode}..."
         year = Virgo.get_260c(bibl.barcode)
         progress_log.info "   ...Found [#{year}]"
         if !year.blank?
            puts "Year for bibl ID #{bibl.id} Barcode #{bibl.barcode} = #{year}"
            if year.to_i < 1923
               progress_log.info "   ...NKC"
               bibl.update_attribute(:use_right_id, nkc.id)
            end
         end
         sleep 0.15  # don't hammer solr constantly
      end
   end

   desc "Populate use rights"
   task :populate  => :environment do
      UseRight.create([
         { :name => 'Copyright Not Evaluated' },
         { :name => 'No Known Copyright' },
         { :name => 'In Copyright' },
         { :name => 'In Copyright Educational Use Permitted' },
         { :name => 'In Copyright Non-Commercial Use Permitted' },
         { :name => 'No Copyright' },
         { :name => 'No Copyright Non-Commercial Use Only' },
         { :name => 'No Copyright Contractual Restrictions' },
         { :name => 'No Copyright Other Known Legal Restrictions' },
         { :name => 'No Copyright United States' },
         { :name => 'All CC Licenses' }])
   end
end
