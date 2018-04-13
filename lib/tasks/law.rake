namespace :law do
   desc "Setup order"
   task :setup  => :environment do
      agency = Agency.find_by(name: "Law Library")
      staff = Customer.find_by(email: "lf6f@virginia.edu")
      o = Order.create!(is_approved: 1, order_title: "Law Library 1828 Master Scans",
         customer: staff, agency: agency, date_order_approved: DateTime.now,
         date_request_submitted: DateTime.now, order_status: "approved",  date_due: (Date.today+1.year))
   end

   desc "Convert to alternate structure"
   task :convert  => :environment do
      json = JSON.parse(File.read('data/lawbooks.json'))
      out = {}
      json['resources'].each do |res|
         book = res['book']
         virgo = book["Virgo"]
         next if virgo.blank?

         # convert structue to a map that has key=catalog_key, each having
         # an array of accociated directory names. Makes it easy to identify
         # multi-volume books
         dir = book['Directory']
         catalog_key = virgo.split("/").last
         if !out.has_key? catalog_key
            out[catalog_key] = [dir]
         else
            out[catalog_key] << dir
         end
      end
      puts out.to_json
   end

   desc 'renumber 0 pages in a unit'
   task :fix_zero => :environment do
      id = ENV['id']
      unit = Unit.find(id)
      pg = 1
      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
      unit.master_files.each do |mf|
         orig_fn = mf.filename
         pg_str = "%04d" % pg
         new_fn = "#{unit_dir}_#{pg_str}.tif"
         puts "MF #{mf.id} page: #{mf.title} filename: #{mf.filename}"
         puts "  UPDATE page: #{pg} filename: #{new_fn}"
         mf.update(title: pg, filename: new_fn)

         orig_arch_path = File.join(archive_dir, orig_fn)
         new_arch_path = File.join(archive_dir, new_fn)
         puts "  RENAME: #{orig_arch_path} => #{new_arch_path}"
         File.rename(orig_arch_path, new_arch_path)

         pg += 1
      end

      unit.reload
      unit.metadata.update(exemplar: unit.master_files.first.filename)
   end

   desc 'renumber pages in a unit'
   task :renumber => :environment do
      id = ENV['id']
      unit = Unit.find(id)
      pg = unit.master_files.count
      unit_dir = "%09d" % unit.id
      archive_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
      unit.master_files.reverse.each do |mf|
         orig_fn = mf.filename
         pg_str = "%04d" % pg
         new_fn = "#{unit_dir}_#{pg_str}.tif"
         puts "MF #{mf.id} page: #{mf.title} filename: #{mf.filename}"
         puts "  UPDATE page: #{pg} filename: #{new_fn}"
         mf.update(title: pg, filename: new_fn)

         orig_arch_path = File.join(archive_dir, orig_fn)
         new_arch_path = File.join(archive_dir, new_fn)
         puts "  RENAME: #{orig_arch_path} => #{new_arch_path}"
         File.rename(orig_arch_path, new_arch_path)

         pg -= 1
      end

      unit.reload
      unit.metadata.update(exemplar: unit.master_files.first.filename)
   end

   desc 'Fix a single book, referenced by catalog key'
   task :single => :environment do
     key = ENV['key']
     id = ENV['id']
     tgt = ENV['dir']
     abort("Key or ID required") if key.blank? && id.blank?

     if !key.blank?
        meta = SirsiMetadata.find_by(catalog_key: key)
     else
        meta = SirsiMetadata.find(id)
        key = meta.catalog_key
     end

     if meta.nil? && !tgt.blank?
        begin
           puts "Creating metadata record for #{key} #{tgt}"
           dir = tgt
           dir_mapper = JSON.parse(File.read('data/law_dir_barcode.json'))
           barcode = dir_mapper[dir]
           if barcode.blank?
              abort "ERROR: NO BARCODE for #{dir} #{key}"
           end
           meta = create_sirsi_record(key, barcode)
           puts "   created ID:#{meta.id}"

           puts "Creating new unit for SirsiMeta #{meta.id}"
           unit = Unit.create(order: order, metadata: meta, intended_use_id: 110, include_in_dl: 1, unit_status: "approved")
        rescue Exception=>e
           abort "ERROR: Unable to find catalog key #{catalog_key}; skipping"
        end
     else
        abort("Metadata not found") if meta.nil?
        puts "Metadata #{meta.id} #{meta.call_number}"

        json = JSON.parse(File.read('data/lawalt.json'))
        dirs = json[key]
        if tgt.blank?
           abort("not a single dir key") if dirs.length > 1
           dir = dirs.first
        else
           abort("#{tgt} not part of this key") if !dirs.include? tgt
           dir = tgt
        end

        unit = meta.units.first
        abort("No Unit") if unit.nil?
     end


     bits = ARCHIVE_DIR.split("/")
     base_dir = bits[0..bits.length-3].join("/")
     base_dir = File.join(base_dir, "1828_Master_Scans")
     src_dir = File.join(base_dir, dir)
     puts "Ingesting tif from #{src_dir}..."

     unit_dir = "%09d" % unit.id
     Dir.glob("#{src_dir}/*.tif").sort.each do |tif|
        src_fn = File.basename(tif, ".*")

        ts_page = src_fn.split(//).last(4).join("")
        if ts_page.to_i.blank?
           ts_page = src_fn.split("_").last
           abort("Coundn't determine page from #{tif}") if ts_page.to_i.blank?
        end
        ts_page="0001" if ts_page == "0000"

        ts_filename = "#{unit_dir}_#{ts_page}.tif"

        # if masterfile with this filename already exists, skip it
        if !MasterFile.find_by(filename: ts_filename).nil?
           puts "   #{ts_filename} already exists; skipping"
           next
        end

        puts "   adding #{tif} as #{ts_filename}"

        # Create MF and tech metadata
        md5 = Digest::MD5.hexdigest(File.read(tif))
        mf = MasterFile.create!(
           unit: unit, filename: ts_filename, filesize: File.size(tif),
           title: ts_page.to_i, md5: md5, metadata: meta)
        TechMetadata.create(mf, tif)

        # Publish and archive
        publish_to_iiif(mf, tif)
        dest_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
        FileUtils.makedirs(dest_dir) if !Dir.exists? dest_dir
        dest_file = File.join(dest_dir, ts_filename )
        FileUtils.copy(tif, dest_file)
        dest_md5 = Digest::MD5.hexdigest(File.read(dest_file))
        mf.update!(date_archived: DateTime.now, date_dl_ingest: DateTime.now)
        if dest_md5 != md5
           puts "ERROR: MD5 does not match for #{filename}"
        end

     end
     # Update metadata (exemplar, date published)
     unit.reload # up to date with newly added MF
     unit.update(master_files_count: unit.master_files.count, date_dl_deliverables_ready: DateTime.now,
        date_archived: DateTime.now, complete_scan: 1)
     exemplar = unit.master_files.first.filename
     unit.metadata.update(exemplar: exemplar, date_dl_ingest: DateTime.now)
     puts "DONE!"
   end

   desc "Generate a barcode json file for multivolume"
   task :barcode_map  => :environment do
      json = JSON.parse(File.read('data/lawalt.json'))
      out = {}

      puts "GENERATE MAPPING----------------------"
      json.each do |catalog_key,dirs|
         barcodes = get_barcodes(catalog_key)
         # puts "#{catalog_key} BARCODES: #{barcodes}"
         # if dirs.length == 1
         #    if barcodes.length > 1
         #       puts "ERROR: #{catalog_key} dir #{dirs.first} has multiple barcodes"
         #       #puts "   #{barcodes.to_json}"
         #    end
         # else
            dirs.each do |dir|
               # hardcode an outlier; part 1 and 2 with unique barcodes
               if dir == "UK_362_1680_V543_1806_v_2_pt_1"
                  out[dir] = "3220693-2001"
                  next
               end
               if dir == "UK_362_1680_V543_1806_v_2_pt_2"
                  out[dir] = "3220693-3001"
                  next
               end
               if barcodes.length == 1 && dirs.length > 1
                  # puts "Multiple volumes mapped to single barcode; #{catalog_key} : #{dir} => barcode=   #{barcodes.first[:barcode]}"
                  # puts "        DETAIL: #{barcodes}"
                  out[dir] = barcodes.first[:barcode]
                  next
               end

               working_dir = dir
               working_dir << "_vol_1" if dir == "Cage_TrialsB_B968r"
               working_dir = working_dir.gsub(/_c_*1/,"")
               working_dir = working_dir.gsub(/_pt_\d/i,"")

               dir_ver = /(v_\d+$|v\d+$|vol_\d+$|book_\d+$|_part_\d+$)/i.match(working_dir).to_s
               if dir_ver.blank?
                  # if barcodes.length > 1
                  #    puts "ERROR: Weird dir name #{dir}"
                  #    puts "  BC: #{barcodes.to_json}"
                  #    next
                  # end
                  out[dir] = barcodes.first[:barcode]
                  puts "    MATCH: #{dir} : #{barcodes.first}"
                  next
               end
               ver_num = dir_ver.gsub(/_part/i,"").gsub(/book/i,"").gsub(/vol/i,"").gsub(/v/i,"").gsub(/_/,"").to_i
               matched = false
               barcodes.each do |info|
                  if (ver_num == 3 || ver_num == 4) && info[:call_number] == "U.K. .46 .G4647E 1795 3-4"
                     matched = true
                     out[dir] = info[:barcode]
                     puts "    MATCH: #{dir} : #{info}"
                     break
                  end
                  hit = /v.\s*#{ver_num}(\s|$)/i.match(info[:call_number]).to_s
                  if !hit.blank?
                     matched = true
                     out[dir] = info[:barcode]
                     puts "    MATCH: #{dir} : #{info}"
                     break
                  end
               end
               if matched == false
                  # if barcodes.length == 1
                     out[dir] = barcodes.first[:barcode]
                     puts "    MATCH: #{dir} : #{barcodes.first}"
                  # else
                  #    puts "ERROR: No call number match for key #{catalog_key}, dir #{dir}: #{barcodes}"
                  # end
               end
            end
         # end
      end
      puts "==================================================================================================="
      puts "#{out.to_json}"
   end

   task :key_barcodes => :environment do
     ck = ENV['key']
     puts "BC: #{get_barcodes(ck)}"
   end

   def get_barcodes(catalog_key)
      marc = Virgo.get_marc_doc(catalog_key)
      marc.remove_namespaces!
      out = []
      marc.xpath("//datafield[@tag='999']").each do |n999|
         cn = n999.at_xpath("subfield[@code='a']")
         next if cn.blank?
         bc = n999.at_xpath("subfield[@code='i']")
         next if bc.blank?
         out << {call_number: cn.text, barcode: bc.text}
      end
      return out
   end

   desc "add barcodes"
   task :add_barcode  => :environment do
      json = JSON.parse(File.read('data/lawbooks.json'))
      mapping = JSON.parse(File.read('data/law_dir_barcode.json'))
      json['resources'].each do |res|
         book = res['book']
         virgo = book["Virgo"]
         next if virgo.blank?

         catalog_key = virgo.split("/").last
         dir = book['Directory']

         # look for prior metadata
         meta = SirsiMetadata.where(catalog_key: catalog_key).first
         next if meta.nil?
         puts "====> Checking MD:#{meta.id} #{catalog_key} in directory: #{dir} .... "

         if meta.barcode.blank?
            bc = mapping[dir]
            if !bc.blank?
               if meta.date_dl_ingest.blank?
                  meta.update(barcode: bc)
               else
                  meta.update(barcode: bc, date_dl_update: Time.now)
               end
               puts "   Metadata #{meta.id}: updated barcode to #{bc}"
            end
         end
      end
   end

   desc "Ingest all law books"
   task :ingest  => :environment do
      bits = ARCHIVE_DIR.split("/")
      base_dir = bits[0..bits.length-3].join("/")
      base_dir = File.join(base_dir, "1828_Master_Scans")
      json = JSON.parse(File.read('data/lawalt.json'))
      dir_mapper = JSON.parse(File.read('data/law_dir_barcode.json'))
      missing = []
      cnt = 0
      order = Order.find_by(order_title: "Law Library 1828 Master Scans")

      skip_me = ['UK_362_1757_E22_v_1', 'UK_362_1757_E22_v_2', 'T_S7993r_1824', 'UK_46_T843_1797']

      puts "Ingesting files from #{base_dir}"
      json.each do |catalog_key, dirs|
         dirs.each do |dir|
            cnt += 1

            # make sure sorce dir exists
            src_dir = File.join(base_dir, dir)
            if !File.exist? src_dir
            #   puts "#{src_dir} NOT FOUND"
               missing << dir
               next
            end
            if skip_me.include? dir
               puts "Skipping #{dir}. Multiple books tied to single catalog key"
               next
            end

            # get a barcode
            barcode = dir_mapper[dir]
            if barcode.blank?
               puts "ERROR: NO BARCODE for #{dir} #{catalog_key}"
               next
            end
            puts "Ingest dir #{dir} to #{catalog_key} : #{barcode}"
            do_ingest(order, src_dir, catalog_key, barcode)
         end
      end
      puts "DONE. #{cnt} books processed. #{missing.length} missing directories."
   end

   def do_ingest(order, src_dir, catalog_key, barcode)
      # look for prior metadata
      meta = SirsiMetadata.where(catalog_key: catalog_key, barcode: barcode).first
      if meta.nil?
         puts "Creating new SirsiMetadata record for #{catalog_key}:#{barcode}"
         begin
            meta = create_sirsi_record(catalog_key, barcode)
            puts "   created ID:#{meta.id}"
         rescue Exception=>e
            puts "ERROR: Unable to find catalog key #{catalog_key}; skipping"
            return
         end
      else
         puts "Using existing SirsiMetadata #{meta.id} record for #{catalog_key}"
      end

      # Create UNIT if necessary
      unit = meta.units.first
      if unit.nil?
         "Creating new unit for SirsiMeta #{meta.id}"
         unit = Unit.create(order: order, metadata: meta, intended_use_id: 110, include_in_dl: 1, unit_status: "approved")
      else
         puts "Using existing unit #{unit.id}"
      end

      # Add master Files
      if unit.master_files.count > 0
         puts "This unit already has master files. SKIPPING"
         return
      end

      unit_dir = "%09d" % unit.id
      Dir.glob("#{src_dir}/*.tif").sort.each do |tif|
         src_fn = File.basename(tif, ".*")
         ts_page = src_fn.split(//).last(4).join("")
         if ts_page.to_i.blank?
            ts_page = src_fn.split("_").last
            abort("Coundn't determine page from #{tif}") if ts_page.to_i.blank?
         end
         ts_page="0001" if ts_page.to_i == 0

         ts_filename = "#{unit_dir}_#{ts_page}.tif"
         puts "   adding #{tif} as #{ts_filename}"

         # if masterfile with this filename already exists, skip it
         next if !MasterFile.find_by(filename: ts_filename).nil?

         # Create MF and tech metadata
         md5 = Digest::MD5.hexdigest(File.read(tif))
         mf = MasterFile.create!(
            unit: unit, filename: ts_filename, filesize: File.size(tif),
            title: ts_page.to_i, md5: md5, metadata: meta)
         TechMetadata.create(mf, tif)

         # Publish and archive
         publish_to_iiif(mf, tif)
         dest_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
         FileUtils.makedirs(dest_dir) if !Dir.exists? dest_dir
         dest_file = File.join(dest_dir, ts_filename )
         FileUtils.copy(tif, dest_file)
         dest_md5 = Digest::MD5.hexdigest(File.read(dest_file))
         mf.update!(date_archived: DateTime.now, date_dl_ingest: DateTime.now)
         if dest_md5 != md5
            puts "ERROR: MD5 does not match for #{filename}"
         end
      end

      # Update metadata (exemplar, date published)
      unit.reload # up to date with newly added MF
      unit.update(master_files_count: unit.master_files.count, date_dl_deliverables_ready: DateTime.now,
         date_archived: DateTime.now, complete_scan: 1)
      exemplar = unit.master_files.first.filename
      unit.metadata.update(exemplar: exemplar, date_dl_ingest: DateTime.now)
   end

   def create_sirsi_record(catalog_key, barcode)
      virgo = Virgo.external_lookup(catalog_key, barcode)
      meta = SirsiMetadata.create(
         discoverability: 1, dpla: 1, parent_metadata_id: 15784,
         use_right_id: 10, is_approved: 1, availability_policy_id: 1,
         title: virgo[:title], creator_name: virgo[:creator_name], catalog_key: catalog_key,
         barcode: virgo[:barcode], call_number: virgo[:call_number], ocr_hint_id: 1
      )
      return meta
   end

   desc "Generate an IIIF manifest report"
   task :report  => :environment do
      # generate a report mapping catalog key to IIIF manifest URL...
      o = Order.find(10274)
      puts "CatalogKey, Barcode, Manifest"
      o.units.each do |u|
         iiif = "#{Settings.virgo_url}/#{u.metadata.pid}/iiif/manifest.json"
         puts "#{u.metadata.catalog_key}, #{u.metadata.barcode}, #{iiif}"
      end
      # either:  http://search.lib.virginia.edu/catalog/tsb:65850/iiif/manifest.json
      # or: https://tracksys.lib.virginia.edu:8080/tsb:65850
   end
end
