namespace :shepherd do
   desc "Setup order/metadata"
   task :setup  => :environment do
      agency = Agency.find_by(name: "Visual History")
      staff = Customer.find_by(email: "lf6f@virginia.edu")
      o = Order.create!(is_approved: 1, order_title: "Charlottesville Walk",
         customer: staff, agency: agency, date_order_approved: DateTime.now,
         date_request_submitted: DateTime.now, order_status: "approved",  date_due: (Date.today+1.year))

      meta = ExternalMetadata.create(
         is_approved: 1, title: "Charlotteville Walk", discoverability: 1, availability_policy_id: 1,
         use_right_id: 3, use_right_rationale: "UVA owns the copyright per deed of gift", dpla: 1,
         ocr_hint_id: 2, external_system: "ArchivesSpace", external_uri: "/repositories/3/resources/273"
      )

      unit = Unit.create(order: o, metadata: meta, intended_use_id: 110, include_in_dl: 1, unit_status: "approved")
      puts "Order #{o.id} metadata #{meta.id} and unit #{unit.id} created"
   end

   desc "Ingest the walk images"
   task :ingest => :environment do
      meta = ExternalMetadata.find_by(title: "Charlotteville Walk")
      abort("Metadata record not found") if meta.nil?
      unit = meta.units.first
      abort("Unit not found") if unit.nil?
      src_dir = ENV['src']
      abort("src param is required") if src_dir.nil?

      unit_dir = "%09d" % unit.id
      Dir.glob("#{src_dir}/*.tif").sort.each do |tif|
         src_fn = File.basename(tif, ".*")
         pg = src_fn.split("_")[0].to_i
         ts_page = "%04d" % pg
         desc = src_fn.split("_")[1]
         ts_filename = "#{unit_dir}_#{ts_page}.tif"
         puts "Processing #{tif} as #{ts_filename}"

         # if masterfile with this filename already exists, skip it
         next if !MasterFile.find_by(filename: ts_filename).nil?

         # Create MF and tech metadata
         md5 = Digest::MD5.hexdigest(File.read(tif))
         mf = MasterFile.create!(
            unit: unit, filename: ts_filename, filesize: File.size(tif),
            title: pg, description: desc, md5: md5, metadata: meta)
         TechMetadata.create(mf, tif)

         # Publish and archive
         publish_to_iiif(mf, tif)
         dest_dir = File.join(ARCHIVE_DIR, "%09d" % unit.id)
         FileUtils.makedirs(dest_dir) if !Dir.exists? dest_dir
         dest_file = File.join(dest_dir, ts_filename )
         puts "Archive to #{dest_file}"
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
end
