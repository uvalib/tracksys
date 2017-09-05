require 'fileutils'

namespace :gannon do

   desc "Setup order/agency"
   task :setup  => :environment do
      agency = Agency.create(name: "Gannon Project")
      staff = Customer.find_by(email: "lf6f@virginia.edu")
      o = Order.create!(is_approved: 1, order_title: "Gannon Digitization Project",
         customer: staff, agency: agency, date_order_approved: DateTime.now,
         date_request_submitted: DateTime.now, order_status: "approved",  date_due: (Date.today+1.year))
   end

   desc "ingest all books"
   task :ingest_all  => :environment do
      excel_dir = File.join(Rails.root, "gannon-excel")
      if !Dir.exists? excel_dir
         abort "Excel dir #{excel_dir} does not exist"
      end

      Dir.foreach(excel_dir) do |f|
         next if !f.include? ".xlsx"
         ENV['barcode'] = f.split(".")[0]
         Rake::Task['gannon:ingest'].execute
      end
   end

   desc "ingest a single book"
   task :ingest  => :environment do
      bc = ENV['barcode']
      abort "barcode is required" if bc.nil?

      excel_file = File.join("gannon-excel", "#{bc}.xlsx")
      image_dir = File.join("gannon-content", bc)

      if !Dir.exists? image_dir
         abort "Image dir #{image_dir} does not exist"
      end
      if !File.exists? excel_file
         abort "Excel file #{excel_file} does not exist"
      end

      # get rights - no copyright US and collection_facet
      rights = UseRight.find(10)
      facet = CollectionFacet.find_by(name: "Gannon Collection")
      avail = AvailabilityPolicy.find(1) # public
      hint = OcrHint.find(1) # text

      # find or create SirsiMetadata record
      sm = SirsiMetadata.find_by(barcode: bc)
      if sm.nil?
         puts "Siri metadata record not found, creating..."
         meta =  nil
         begin
            meta = Virgo.external_lookup(nil, bc)
         rescue Exception=>e
            puts "ERROR: Unable to find barcode #{bc}; skipping"
            next
         end
         sm = SirsiMetadata.create(is_approved: true,
            barcode: bc, catalog_key: meta[:catalog_key], call_number: meta[:call_number],
            title: meta[:title], creator_name: meta[:creator_name],
            availability_policy: avail, use_right: rights,
            parent_metadata_id: 15784, dpla: 1, discoverability: 1,
            collection_facet: facet.name, ocr_hint: hint, date_dl_ingest: DateTime.now)
      end

      if sm.units.count == 0
         puts "Creating new unit"
         o = Order.find_by(order_title: "Gannon Digitization Project")
         unit = Unit.create(order: o, metadata: sm, intended_use_id: 110, include_in_dl: 1, unit_status: "approved")
         puts "Created new unit #{unit.as_json}"
      else
         unit = sm.units.first
      end

     if unit.master_files.count > 0
        puts "This unit already has master files. SKIPPING"
        next
     end

      xlsx = Roo::Spreadsheet.open(excel_file)
      csv_data = xlsx.to_csv
      mf_cnt = 0
      exemplar = nil
      found_title_page = false
      unit_dir = "%09d" % unit.id
      CSV.parse(csv_data, headers: true) do |row|
         next if row[0].blank?
         filename = row[0]
         exemplar = filename if exemplar.nil?

         title = row[1]
         img_file = File.join(image_dir, filename)
         if !File.exists? img_file
            puts "WARNING: Unable to find source image #{img_file}; trying alternate extension"
            if img_file.include? ".tif"
               img_file = img_file.gsub(/\.tif/, ".jp2")
               filename = filename.gsub(/\.tif/, ".jp2")
            else
               img_file = img_file.gsub(/\.jp2/, ".tif")
               filename = filename.gsub(/\.jp2/, ".tif")
            end
            if !File.exists? img_file
               puts "ERROR: Unable to find source image #{img_file}; skipping"
               next
            end
         end
         puts "Processing #{filename}..."

         mf_cnt += 1

         # convert filename from source folder to tracksys scheme
         fn_page = "%04d" % filename.to_i
         ts_filename = "#{unit_dir}_#{fn_page}.#{filename.split('.')[1]}"
         ts_txt_filename = "#{unit_dir}_#{fn_page}.txt"

         # Set exemplar to the title page if possible, or page 1.
         # default is first image if neither is found
         if !title.blank?
            if title.strip.downcase == "title-page"
               found_title_page = true
               exemplar = ts_filename
            end
            if title.strip.downcase == "1" && found_title_page == false
               exemplar = ts_filename
            end
         end

         # Before anything else happens, run identify on the file to see if it is valid
         cmd = "identify #{img_file}"
         if !system(cmd)
            puts "ERROR: File #{img_file} is invalid. Skipping"
            next
         end

         # if masterfile with this filename already exists, skip it
         next if !MasterFile.find_by(filename: ts_filename).nil?

         md5 = Digest::MD5.hexdigest(File.read(img_file))
         mf = MasterFile.create!(unit: unit, filename: ts_filename, filesize: File.size(img_file),
            title: title, md5: md5, metadata: sm)

         # create tech metadata
         no_tech_metadata = false
         begin
            TechMetadata.create(mf, img_file)
         rescue Exception => e
            puts "WARN: Unable to generate tech metadata #{e}"
            no_tech_metadata = true
         end

         file_type = "TIFF"
         if filename.include? ".jp2"
            pth = iiif_path(mf.pid)
            FileUtils.copy(img_file, pth)
            file_type = "JP2"
         else
            publish_to_iiif(mf, img_file)
         end

         # if we were previously unable to get any tech metadata, ask
         # the iiif server for some.
         if no_tech_metadata
            puts "Attempting to get minimal tech metadta from IIIF server"
            resp = RestClient.get("#{Settings.iiif_url}/#{mf.pid}/info.json")
            if resp.code == 200
               json = JSON.parse(resp.body)
               ImageTechMeta.create(master_file: mf, width: json["width"],
                  height: json["height"], image_format: file_type)
            else
               puts "WARN: unable to retreive info for #{mf.pid} from IIIF server"
            end
         end

         # Update MF with OCR text
         text_filename = "#{filename.split('.')[0]}.txt"
         txt_file = File.join(image_dir,  text_filename)
         file = File.open(txt_file, "rb")
         ocr_txt = file.read
         file.close
         mf.update!(transcription_text: ocr_txt, text_source: 0)

         # Archive!
         dest_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
         FileUtils.makedirs(dest_dir) if !Dir.exists? dest_dir

         dest_file = File.join(dest_dir, ts_txt_filename )
         FileUtils.copy(txt_file, dest_file)

         dest_file = File.join(dest_dir, ts_filename )
         FileUtils.copy(img_file, dest_file)
         dest_md5 = Digest::MD5.hexdigest(File.read(dest_file))
         mf.update!(date_archived: DateTime.now, date_dl_ingest: DateTime.now)
         if dest_md5 != md5
            puts "ERROR: MD5 does not match for #{filename}"
         end
      end

      # all MF ingested. Grab unit and update relevant stats
      unit.reload # up to date with newly added MF
      if unit.master_files.count != mf_cnt
         puts "WARN: unit master files count #{unit.master_files.count} mismatch file count #{mf_cnt}"
      end

      unit.update(master_files_count: mf_cnt, date_dl_deliverables_ready: DateTime.now,
         date_archived: DateTime.now, complete_scan: 1)
      unit.metadata.update(exemplar: exemplar)
   end

   desc "Fix missing jp2 metadata"
   task :fix_metadata  => :environment do
      id = ENV["id"]
      abort("ID is required") if id.nil?
      mf = MasterFile.find(id)
      abort("Master file already has tech metadata") if !mf.image_tech_meta.nil?
      file_type="TIFF"
      file_type="JP2" if mf.filename.include? ".jp2"

      puts "Attempting to get minimal texh metadta from IIIF server"
      resp = RestClient.get("#{Settings.iiif_url}/#{mf.pid}/info.json")
      if resp.code == 200
         json = JSON.parse(resp.body)
         ImageTechMeta.create(master_file: mf, width: json["width"],
            height: json["height"], image_format: file_type)
      else
         puts "WARN: unable to retreive info for #{mf.pid} from IIIF server"
      end
   end

   desc "fix filenames"
   task :fix_filenames  => :environment do
      id = ENV["id"]
      abort("ID is required") if id.nil?
      unit = Unit.find(id)
      archive_root_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
      unit_dir = "%09d" % unit.id
      puts "Update all master file names for unit #{id} to match naming convention..."
      unit.master_files.each do |mf|
         orig_fn = mf.filename
         puts "Processing #{orig_fn}..."
         if /\d{9}_\d{4}\..{3}/.match(orig_fn)
            puts "Filename #{orig_fn} already in correct format. Skipping."
            next
         end

         fn_page = "%04d" % orig_fn.to_i
         new_fn = "#{unit_dir}_#{fn_page}.#{orig_fn.split('.')[1]}"

         puts "   Update #{orig_fn} to #{new_fn}..."
         orig_archive = File.join(archive_root_dir, orig_fn)
         new_archive = File.join(archive_root_dir, new_fn)
         File.rename(orig_archive, new_archive)

         txt_fn = "#{orig_fn.split('.')[0]}.txt"
         orig_archive = File.join(archive_root_dir, txt_fn)
         txt_fn = "#{new_fn.split('.')[0]}.txt"
         new_archive = File.join(archive_root_dir, txt_fn)
         File.rename(orig_archive, new_archive)

         mf.update(filename: new_fn)
      end
      puts "DONE"
   end

   desc "Republish all"
   task :republish  => :environment do
      Metadata.joins(:units).joins(:orders).joins(:agencies).where("agencies.name=?","Gannon Project").each do |m|
         m.update(date_dl_update: DateTime.now)
      end
   end
end
