require 'fileutils'

namespace :gannon do
   desc "fix revered pages"
   task :fix_transcriptions => :environment do
      unit_dir = "%09d" % 50542
      archive_dir = File.join(ARCHIVE_DIR, unit_dir)
      txt_dir = "/digiserv-production/scan/01_from_archive/lf6f/reversed"
      Unit.find(50542).master_files.each do |mf|
        txt =  "#{mf.filename.split(".")[0]}.txt"
        fn = File.join(txt_dir, txt)
        next if !File.exist? fn

        puts "Updating transcription for #{mf.id}"
        f = File.open(fn, "r")
        trans = f.read
        f.close
        mf.update( transcription_text: trans)

        dest = File.join(archive_dir, txt)
        puts "Archive text file to: #{dest}"
        FileUtils.copy(fn, dest)
        FileUtils.chmod(0664, dest) 
      end  
   end 

   desc "Setup order/agency"
   task :setup  => :environment do
      agency = Agency.create(name: "Gannon Project")
      staff = Customer.find_by(email: "lf6f@virginia.edu")
      o = Order.create!(is_approved: 1, order_title: "Gannon Digitization Project",
         customer: staff, agency: agency, date_order_approved: DateTime.now,
         date_request_submitted: DateTime.now, order_status: "approved",  date_due: (Date.today+1.year))
   end

   desc "ingest RAW books"
   task :ingest_raw  => :environment do
      info = {
         rights: UseRight.find(10),
         facet: CollectionFacet.find_by(name: "Gannon Collection"),
         avail: AvailabilityPolicy.find(1), # public
         hint: OcrHint.find(1), # text
         order: Order.find_by(order_title: "Gannon Digitization Project")
      }

      max = 100
      cnt = 0
      Dir.glob("/digiserv-production/Gannon-Final/X*").each do |dir|
         next if File.basename(dir).size > 10
         barcode = File.basename(dir)

         # First; metadata
         sm = SirsiMetadata.find_by(barcode: barcode)
         if sm.nil?
            sm = create_metadata(barcode, info)
            next if sm.nil?
         else
            puts "Using existing SirsiMetadata #{sm.id} for barcode #{barcode}"
         end

         # Second - UNIT
         if sm.units.count == 0
            unit = Unit.create(order: info[:order], metadata: sm, intended_use_id: 110, include_in_dl: 1, unit_status: "approved")
            puts "Created new unit #{unit.as_json}"
         else
            puts "Using existing unit #{sm.units.first.id}"
            unit = sm.units.first
         end

        if unit.master_files.count > 0
           puts "Unit #{unit.id} already has master files. SKIPPING"
           next
        end

        ingest_raw_files(sm, unit, dir)
        cnt +=1
        if cnt >= max
           puts "INGEST #{cnt} BARCODES; STOPPING"
           break
        end
      end
   end

   def create_metadata(bc, info)
      puts "Creating SiriMetadata record for #{bc}"
      meta =  nil
      begin
         meta = Virgo.external_lookup(nil, bc)
      rescue Exception=>e
         puts "ERROR: Unable to find barcode #{bc}; skipping"
         return nil
      end
      sm = SirsiMetadata.create(is_approved: true,
         barcode: bc, catalog_key: meta[:catalog_key], call_number: meta[:call_number],
         title: meta[:title], creator_name: meta[:creator_name],
         availability_policy: info[:avail], use_right: info[:rights],
         parent_metadata_id: 15784, dpla: 1, discoverability: 1,
         collection_facet: info[:facet].name, ocr_hint: info[:hint], date_dl_ingest: DateTime.now)
      return sm
   end

   desc "ingest single RAW book by barcode"
   task :ingest_raw_barcode  => :environment do
      bc = ENV['barcode']
      abort("Barcode is required") if bc.nil?
      sm = SirsiMetadata.find_by(barcode: bc)
      abort("Metadata for #{bc} not found") if sm.nil?
      unit = sm.units.first
      abort("Unit for #{bc} not found") if unit.nil?
      dir = "/digiserv-production/Gannon-Final/#{bc}"
      abort("#{dir} not found") if !Dir.exists?(dir)
      puts "Ingest files for #{bc}..."
      ingest_raw_files(sm, unit, dir)
      puts "DONE"
   end

   def ingest_raw_files(sm, unit, dir)
      images = [".tif", ".jp2"]
      unit_dir = "%09d" % unit.id

      Dir["#{dir}/*"].sort.each do |file|
         next if !images.include? File.extname(file)
         puts "Processing #{file}..."

         # convert filename from source folder to tracksys scheme
         img_file = File.basename(file)
         fn_page = "%04d" % img_file.to_i
         ts_filename = "#{unit_dir}_#{fn_page}.#{img_file.split('.')[1]}"
         ts_txt_filename = "#{unit_dir}_#{fn_page}.txt"

         # if masterfile with this filename already exists, skip it
         if !MasterFile.find_by(filename: ts_filename).nil?
            print "."
            next
         end

         # Before anything else happens, run identify on the file to see if it is valid
         cmd = "identify #{file}"
         if !system(cmd)
            puts "ERROR: File #{file} is invalid. Skipping"
            next
         end

         md5 = Digest::MD5.hexdigest(File.read(file))
         mf = MasterFile.create!(unit: unit, filename: ts_filename, filesize: File.size(file),
            title: "#{img_file.to_i}", md5: md5, metadata: sm)
         TechMetadata.create(mf, file)

         file_type = "TIFF"
         if img_file.include? ".jp2"
            pth = iiif_path(mf.pid)
            FileUtils.copy(file, pth)
            file_type = "JP2"
         else
            publish_to_iiif(mf, file)
         end

         # Update MF with OCR text
         txt_file = "#{file.split('.')[0]}.txt"
         tf = File.open(txt_file, "rb")
         ocr_txt = tf.read
         tf.close
         mf.update!(transcription_text: ocr_txt, text_source: 0)

         # Archive!
         dest_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
         FileUtils.makedirs(dest_dir) if !Dir.exists? dest_dir

         dest_file = File.join(dest_dir, ts_txt_filename )
         FileUtils.copy(txt_file, dest_file)

         dest_file = File.join(dest_dir, ts_filename )
         FileUtils.copy(file, dest_file)
         dest_md5 = Digest::MD5.hexdigest(File.read(dest_file))
         mf.update!(date_archived: DateTime.now, date_dl_ingest: DateTime.now)
         if dest_md5 != md5
            puts "ERROR: MD5 does not match for #{ts_filename}"
         end
      end

      unit.reload # up to date with newly added MF
      unit.update(master_files_count: unit.master_files.count, date_dl_deliverables_ready: DateTime.now,
         date_archived: DateTime.now, complete_scan: 1)
      unit.metadata.update(exemplar:  unit.master_files.first.filename)
   end

   desc "ingest all books"
   task :ingest_all  => :environment do
      name = ENV['name']
      abort("Name is required") if name.nil?

      excel_dir = File.join(Rails.root, "gannon-#{name}")
      if !Dir.exists? excel_dir
         abort "Excel dir #{excel_dir} does not exist"
      end

      Dir.foreach(excel_dir) do |f|
         next if !f.include? ".xlsx"
         ENV['barcode'] = f.split(".")[0]
         Rake::Task['gannon:ingest'].execute
      end
   end

   desc "ingest all books"
   task :ingest_all  => :environment do
      name = ENV['name']
      abort("Name is required") if name.nil?

      excel_dir = File.join(Rails.root, "gannon-#{name}")
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
      name = ENV['name']
      abort("Name is required") if name.nil?
      abort "barcode is required" if bc.nil?

      excel_file = File.join("gannon-#{name}", "#{bc}.xlsx")
      image_dir = File.join("gannon-content", bc)

      if !Dir.exists? image_dir
         puts "ERROR: Image dir #{image_dir} does not exist"
         next
      end
      if !File.exists? excel_file
         puts "ERROR: Excel file #{excel_file} does not exist"
         next
      end

      # get rights - no copyright US and collection_facet
      rights = UseRight.find(10)
      facet = CollectionFacet.find_by(name: "Gannon Collection")
      avail = AvailabilityPolicy.find(1) # public
      hint = OcrHint.find(1) # text

      # find or create SirsiMetadata record
      sm = SirsiMetadata.find_by(barcode: bc)
      if sm.nil?
         puts "Siri metadata record for #{bc} not found, creating..."
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
      else
         puts "Using existing SirsiMetadata #{sm.id} for barcode #{bc}"
      end

      if sm.units.count == 0
         puts "Creating new unit"
         o = Order.find_by(order_title: "Gannon Digitization Project")
         unit = Unit.create(order: o, metadata: sm, intended_use_id: 110, include_in_dl: 1, unit_status: "approved")
         puts "Created new unit #{unit.as_json}"
      else
         puts "Using existing unit"
         unit = sm.units.first
      end

     if unit.master_files.count > 0
#        puts "This unit already has master files. SKIPPING"
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
      exemplar = unit.master_files.first.filename if exemplar.nil?
      unit.metadata.update(exemplar: exemplar)
   end

   desc "Fix ALL missing jp2 dimensions metadata"
   task :fix_missing_size  => :environment do
      o = Order.find_by(order_title: "Gannon Digitization Project")
      o.units.where("created_at > ?", "2018-01-01").each do |unit|
         unit.metadata.update(date_dl_update: Time.now)
         puts "CHECK UNIT #{unit.id}..."
         unit.master_files.joins(:image_tech_meta).where("image_tech_meta.width is null").each do |mf|
           img_path = MasterFile.iiif_path(mf.pid)
           puts "   MF #{mf.id} missing dimensions"
           image = Magick::Image.ping(img_path).first
           dims = image.inspect.split(" ")[2]
           mf.image_tech_meta.update(width: dims.split("x")[0], height: dims.split("x")[1])
           mf.update(date_dl_update: Time.now)
           puts "     updated to #{mf.image_tech_meta.width}x#{mf.image_tech_meta.height}"
         end
      end
   end

   desc "Fix bad exemplar"
   task :fix_exemplar  => :environment do
      Metadata.where(exemplar: "00000001.jp2").each do |m|
         e = m.units.first.master_files.first.filename
         puts "Update #{m.id}: #{m.barcode} exemplar to #{e}"
         m.update(exemplar: e, date_dl_update: Time.now)
      end
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
