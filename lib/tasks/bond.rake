namespace :bond do
   ORDER_TITLE="Bond papers boxes 4 and 5"

   desc "Create julian bond agency"
   task :create_agency  => :environment do
      a = Agency.find_by(name: "Julian Bond Papers")
      if a.nil?
         puts "Creating agency for 'Julian Bond Papers'"
         Agency.create(name: "Julian Bond Papers", description: "Julian Bond papers digitizaed by Center for Digital Editing",
            ancestry: "51", names_depth_cache: "Internal Administrative Unit")
      end
   end

   desc "Create location records for folders in boxes 4 and 5"
   task :create_locations  => :environment do
      puts "Looking up metadata records for box 4 and box 5..."
      box4 = SirsiMetadata.find_by(barcode: "X030098648")   # BOX 4 metadata
      box5 = SirsiMetadata.find_by(barcode: "X030098649")   # BOX 5 metadata
      if box4.nil? || box5.nil?
         abort "Box4 and/or Box5 metadata record missing. Please create them now."
      end
      puts "BOX 4: #{box4.id}"
      puts "BOX 5: #{box5.id}"

      puts "Lookup box container type..."
      box_type = ContainerType.find_by(name: "Box")

      puts "Parse CSV for locations..."
      csv_file = File.join(Rails.root,  "data", "BondPapers-Series1-box1-5.csv")
      cnt = 0
      CSV.parse( File.read(csv_file), headers: true ).each do |row|
         # col 1: title, col 8: BOX/FOLDER, col 9: num pages, col 10: filenames with | sep
         # Box format: "Box # Folder #"
         puts "Create location #{row[8]}"
         bits = row[8].split(" ")
         box_num = bits[1]
         folder_num = bits[3]
         md_rec = box5
         md_rec = box4 if box_num == "4"

         exist = Location.where("metadata_id=? and container_type_id=? and container_id=? and folder_id=?",
            md_rec.id,  box_type.id, box_num, folder_num).first
         if exist.nil?
            Location.create!(metadata_id: md_rec.id, container_type_id: box_type.id, container_id: box_num, folder_id: folder_num)
            cnt +=1
         else
            puts "Location #{row[8]} already exists"
         end
      end
      puts "DONE. #{cnt} locations created"
   end

   desc "Ingest images from folders in boxes 4 and 5"
   task :ingest_images  => :environment do
      puts "Looking up metadata records for box 4 and box 5..."
      box4 = SirsiMetadata.find_by(barcode: "X030098648")   # BOX 4 metadata
      box5 = SirsiMetadata.find_by(barcode: "X030098649")   # BOX 5 metadata
      if box4.nil? || box5.nil?
         abort "   ERROR: Box4 and/or Box5 metadata record missing. Please create them now."
      end
      puts "   BOX 4: #{box4.id}"
      puts "   BOX 5: #{box5.id}"

      puts "Lookup order record..."
      order = Order.find_by(order_title: ORDER_TITLE)
      if order.nil?
         abort "   ERROR: Order record missing. Please create it now."
      end
      puts "   ORDER: #{order.id}"
      if !order.date_order_approved?
         puts "   marking order as approved before adding units/master files..."
         if !order.update(date_order_approved: Time.now, order_status: 'approved')
            abort order.errors.full_messages.to_sentence
         end
      end

      puts "Lookup box container type..."
      box_type = ContainerType.find_by(name: "Box")

      src_dir = File.join(Settings.production_mount, "bondpapers")
      puts "Base images directory: #{src_dir}"

      puts "Parse CSV for master files..."
      csv_file = File.join(Rails.root,  "data", "BondPapers-Series1-box1-5.csv")
      cnt = 0
      row_count = 0
      CSV.parse( File.read(csv_file), headers: true ).each do |row|
         # col 1: title, col 8: BOX/FOLDER, col 9: num pages, col 10: filenames with | sep
         puts "Get or create unit for #{row[0]}: #{row[1]}"
         bits = row[8].split(" ")
         box_num = bits[1]
         folder_num = bits[3]
         title = row[1]
         md_rec = box4
         md_rec = box5 if box_num == "5"
         unit = Unit.where("order_id=? and metadata_id=? and staff_notes=?", order.id, md_rec.id, title).first
         if unit.nil?
            puts "   create unit for [#{title}]..."
            unit = Unit.create(
               metadata: md_rec, unit_status: "approved", order: order,
               intended_use_id: 110, staff_notes: title, include_in_dl: 0
            )
            puts "   created unit #{unit.id}"
         else
            puts "   found existing unit #{unit.id}"
            if unit.unit_status == "done"
               puts "   unit #{unit.id} is already done; skipping"
               next
            end
         end

         # setup working dir for processing the images for this unit
         work_dir = File.join(Settings.production_mount, "finalization", "tmp", unit.directory)
         FileUtils.mkdir_p(work_dir) if !Dir.exist? work_dir
         puts "   unit working directory #{work_dir}"

         # grab the list of images from row 10 and ingest each one
         puts "Get all images for #{row[8]}"
         unit_mf_count = 0
         folder_dir = File.join(src_dir, "Box\ #{box_num}", "mss13347-b4-f#{folder_num}", "TIFF")
         row[10].split("|").each_with_index do |src_fn, idx|
            # get source and working file names
            src_fn.strip!
            src_mf_path = File.join(folder_dir, src_fn)
            mf_seq = "%04d" % (idx+1)
            dest_fn = "#{unit.directory}_#{mf_seq}.tif"
            work_mf_path = File.join(work_dir, dest_fn)
            puts "   [#{idx+1}] ingest #{src_mf_path} as #{dest_fn}..."

            # source or workfile must exist
            if File.exists?(work_mf_path)
               puts "      source file has already been copied to the work dir"
            else
               if File.exists?(src_mf_path) == false
                  abort "ERROR: source #{src_mf_path} or working #{work_mf_path} not found"
               else
                  # NOTE: must copy because the original files are root owned and read-only
                  puts "      copy #{src_mf_path} to "
                  puts "           #{work_mf_path}"
                  FileUtils.cp( src_mf_path, work_mf_path)
                  src_md5 = Digest::MD5.hexdigest(File.read(src_mf_path) )
                  md5 = Digest::MD5.hexdigest(File.read(work_mf_path) )
                  if src_md5 != md5
                     puts "      WARNING: src/working file checksum mismatch"
                  end
                  puts "      COPIED"
               end
            end

            # from this point on, just work with work_mf_path
            #
            # create master_file record
            master_file = MasterFile.find_by(unit_id: unit.id, filename: dest_fn )
            if master_file.nil?
               puts "      create new master file #{dest_fn}"
               master_file = MasterFile.new(filename: dest_fn, unit_id: unit.id, metadata_id: md_rec.id,
                  filesize: File.size(work_mf_path),
                  title: "#{idx+1}",
                  md5: Digest::MD5.hexdigest(File.read(work_mf_path) ) )
               if idx == 0
                  master_file.description = title
               end
               if !master_file.save
                  abort "      ERROR: #{dest_fn}': #{master_file.errors.full_messages}"
               end
            else
               puts "      master file #{dest_fn} already exists"
            end

            # create image tech metadata
            if master_file.image_tech_meta.nil?
               puts "      create tech metadata for #{dest_fn}"
               TechMetadata.create(master_file, work_mf_path)
            end

            # add a tag with the original file name
            if master_file.tags.first.nil?
               puts "      add tag [#{src_fn}] to #{dest_fn}"
               master_file.add_new_tag(src_fn)
            end

            # publish to IIIF
            puts "      publishing to IIIF..."
            IIIF.publish(work_mf_path, master_file, false)

            # archive image
            if unit.date_archived.blank?
               puts "      archiving image..."
               Archive.publish(work_mf_path, master_file)
            end

            cnt += 1
            unit_mf_count += 1
         end

         # all masterfiles have been added to the unit. Cleanup unit directory in finalization/tmp
         puts "   unit COMPLETE, clean up work directory"
         FileUtils.rm_rf(work_dir) if Dir.exist? work_dir
         if !unit.date_archived?
            puts "   marking unit complete and archived"
            unit.update(date_archived: Time.now, unit_status: 'done', master_files_count: unit_mf_count)
         end

         row_count +=1
         break if row_count == 1
      end
      puts "DONE. #{cnt} master files ingested from #{row_count} CSV rows"
   end
end
