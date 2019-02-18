require 'fileutils'

namespace :rights do

   desc "Fix Holsinger rights info"
   task :fix_holsinger  => :environment do
      ignore_dates = ["undated", "unknown date", "unknown", "n.d."]
      cnt = 0
      skipped = 0
      Metadata.where(parent_metadata_id: 3002).find_each do |md|
         # Note all are XML Metadata
         doc = Nokogiri::XML(md.desc_metadata)
         doc.remove_namespaces!
         dates = []
         doc.xpath("/mods/originInfo/dateCreated").each do |n|
            next if ignore_dates.include? n.text.strip.downcase
            clean_date = QDC.clean_xml_text(n.text)
            # detect dates like: 1975-05-17/18 and toss the info after the slash
            if /\d{4}-\d{1,2}-\d{1,2}/.match(clean_date) && clean_date.include?("/")
               clean_date = clean_date.split("/")[0]
            end
            dates << clean_date
         end
         # Pick latest date and replace U or X with 9. Format: YYYY-MM-DD
         if dates.blank?
            puts "MD #{md.id} has no date. Current rights: #{md.use_right.name}"
            skipped += 1
            next
         end
         date = dates.sort.last
         year_str = date.split("-")[0]
         if /[ux]/i.match(year_str)
            puts "MD #{md.id} has unknown in date '#{date}' - current rights: #{md.use_right.name}"
            skipped += 1
            next
         end
         year = year_str.to_i
         if year.to_i > 1896
            puts "MD #{md.id} '#{date}' is post-1896, set to InC (3)"
            md.update(use_right_id: 3, date_dl_update: Time.now)
            md.master_files.update_all(date_dl_update: Time.now)
         else
            puts "MD #{md.id} '#{date}' is 1896 or earlier, set to NoC-US (10)"
            md.update(use_right_id: 10, date_dl_update: Time.now)
            md.master_files.update_all(date_dl_update: Time.now)
         end
         cnt +=1
      end
      puts "DONE. #{cnt} records updated, #{skipped} records skipped"
   end

   desc "Fix Jackson Davis rights info"
   task :fix_jd  => :environment do
      Metadata.where(parent_metadata_id: 3109).update_all(use_right_id: 10, creator_death_date: 1947, use_right_rationale: "Jackson Davis died in 1947")
   end

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

   desc "Fix MS Bibls that are in Virgo. Set to NKC"
   task :bibl_nkc_fix  => :environment do
      # if a bibl is a manuscript and is in virgo, mark it as NKC
      nkc = UseRight.find_by(name: "No Known Copyright")
      puts "Update manuscript Bibl that are in digital Library as NKC..."
      Bibl.where('is_manuscript=1').where(use_right_id: 1).where.not(date_dl_ingest: nil).update_all(use_right_id: nkc.id)
   end

   desc "report of NKC bibls in digital library"
   task :report  => :environment do
      # if a bibl is a manuscript and is in virgo, mark it as NKC
      nkc = UseRight.find_by(name: "No Known Copyright")
      f = File.open(Rails.root.join("log", "rights_report.csv"),"w")
      f << "ID\tTitle\tBarcode\tCall Number\tRaw Date\tDate\tPlace of Publication\n"
      f << "\n"
      puts "Report file created, adding data..."
      cnt = 0
      Bibl.where(use_right_id: nkc.id).where.not(date_dl_ingest: nil).find_each do |bibl|
         info = Virgo.get_marc_publication_info( bibl.barcode )
         place = ""
         place = info[:place] if !info.nil?
         f << "#{bibl.id}\t#{bibl.title}\t#{bibl.barcode}\t#{bibl.call_number}\t#{bibl.year}\t#{Virgo.extract_year_from_raw_260c(bibl.year)}\t#{place}\n"
         sleep 0.1
      end
      puts "DONE"
      f.close
   end

   desc "Add place of publication"
   task :add_pub_place  => :environment do
      progress_logfile = "log/pub_place.log"
      progress_log = Logger.new(progress_logfile)
      progress_log.formatter = proc do |severity, datetime, progname, msg|
         "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{severity} : #{msg}\n"
      end

      # check bibls with year data (this year field is extracted from the MARC 260c)
      puts "start processing..."
      progress_log.info "Checking all bibl records with a barcode or catalog key..."
      Bibl.where.not(barcode: nil).where.not(catalog_key: nil).find_each do |bibl|
         info = Virgo.get_marc_publication_info(bibl.barcode, bibl.catalog_key)
         progress_log.info "Bibl ID #{bibl.id} catalog key #{bibl.catalog_key} published in #{info[:place]}"
         bibl.update_attribute(:publication_place, info[:place] ) if !info[:place].blank?
         sleep 0.15  # don't hammer solr constantly
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
      #        DP                 our MW, DL BAD     our MW DL, BAD     C&C in DL          invalid            no DL
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

   desc "UPDATE use rights to match DPLA"
   task :update  => :environment do
      u = UseRight.find_by(name: "All CC Licenses")
      u.update(name: "Copyright Undetermined")
      u = UseRight.find_by(name: "No Copyright")
      u.update(name: "In Copyright Rights Holder Unlocatable")
      UseRight.find_by(name: "No Copyright Contractual Restrictions").destroy
      UseRight.find_by(name: "No Copyright Non-Commercial Use Only").destroy
   end

   desc "UPDATE use rights to match DPLA"
   task :add_uri  => :environment do
      data  = [
         {name: "Copyright Not Evaluated", uri: "http://rightsstatements.org/page/CNE/1.0/"},
         {name: "Copyright Undetermined", uri: "http://rightsstatements.org/page/UND/1.0/"},
         {name: "In Copyright", uri: "http://rightsstatements.org/page/InC/1.0/"},
         {name: "In Copyright Educational Use Permitted", uri: "http://rightsstatements.org/page/InC-EDU/1.0/"},
         {name: "In Copyright Non-Commercial Use Permitted", uri: "http://rightsstatements.org/page/InC-NC/1.0/"},
         {name: "In Copyright Rights Holder Unlocatable", uri: "http://rightsstatements.org/page/InC-RUU/1.0/"},
         {name: "No Copyright Other Known Legal Restrictions", uri: "http://rightsstatements.org/page/NoC-OKLR/1.0/"},
         {name: "No Copyright United States", uri: "http://rightsstatements.org/page/NoC-US/1.0/"},
         {name: "No Known Copyright", uri: "http://rightsstatements.org/page/NKC/1.0/"}
      ]
      data.each do |d|
         u = UseRight.find_by(name: d[:name])
         u.update(uri: d[:uri])
      end
   end

   desc "UPDATE use rights to to include wrapper statement and permission flags"
   task :add_details  => :environment do
      file = File.read("data/rights.json")
      rights = JSON.parse(file)
      rights['statements'].each do |s|
         ur = UseRight.find_by(uri: s['uri'])
         if ur.nil?
            puts "ERROR: Couldn't find use right with URI #{s['uri']}"
            next
         end
         statement = s['statement'].join("\n")
         ur.update!(statement: statement, educational_use: s['use'].include?("education"),
            commercial_use: s['use'].include?("commercial"), modifications: s['use'].include?("modify"))
      end
   end
end
