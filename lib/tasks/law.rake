namespace :law do
   desc "Setup order"
   task :setup  => :environment do
      agency = Agency.find_by(name: "Law Library")
      staff = Customer.find_by(email: "lf6f@virginia.edu")
      o = Order.create!(is_approved: 1, order_title: "Law Library 1828 Master Scans",
         customer: staff, agency: agency, date_order_approved: DateTime.now,
         date_request_submitted: DateTime.now, order_status: "approved",  date_due: (Date.today+1.year))
   end

   desc "Ingest all law books"
   task :ingest  => :environment do
      bits = ARCHIVE_DIR.split("/")
      base_dir = bits[0..bits.length-3].join("/")
      base_dir = File.join(base_dir, "1828 Master Scans")
      json = JSON.parse(File.read('data/lawbooks.json'))
      missing = []
      cnt = 0
      errors = 0
      order = Order.find_by(order_title: "Law Library 1828 Master Scans")

      puts "Ingesting files from #{base_dir}"
      json['resources'].each do |res|
         cnt += 1
         book = res['book']
         virgo = book["Virgo"]
         catalog_key = virgo.split("/").last
         dir = book['Directory']
         src_dir = File.join(base_dir, dir)
         if !File.exist? src_dir
            puts "#{src_dir} NOT FOUND"
            missing << dir
            next
         end

         # look for prior metadata
         meta = SirsiMetadata.where(catalog_key: catalog_key).first
         if meta.nil?
            puts "Creating new SirsiMetadata record for #{catalog_key}"
            begin
               virgo = Virgo.external_lookup(catalog_key, nil)
               meta = SirsiMetadata.create(
                  discoverability: 1, dpla: 1, parent_metadata_id: 15784,
                  use_right_id: 10, is_approved: 1, availability_policy_id: 1,
                  title: virgo[:title], creator_name: virgo[:creator_name], catalog_key: catalog_key,
                  barcode: virgo[:barcode], call_number: virgo[:call_number], ocr_hint_id: 1
               )
            rescue Exception=>e
               puts "ERROR: Unable to find catalog key #{catalog_key}; skipping"
               next
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
            next
         end
         unit_dir = "%09d" % unit.id
         Dir.glob("#{src_dir}/*.tif").sort.each do |tif|
            src_fn = File.basename(tif, ".*")
            ts_page = src_fn.split("_").last
            ts_filename = "#{unit_dir}_#{ts_page}.tif"
            puts "   adding #{tif} as #{ts_filename}"

            cmd = "identify '#{tif}'"
            if !system(cmd)
               puts "ERROR: File #{tif} is invalid. Skipping"
               next
            end

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
      puts "DONE. #{cnt} books processed. #{missing.length} missing directories. #{errors} errors."
   end
end
