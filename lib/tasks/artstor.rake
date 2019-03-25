namespace :artstor do

   desc "test metadata"
   task :test  => :environment do
      fn = ENV['file']
      js = ExternalSystem.find_by(name: "JSTOR Forum")
      cookies = Jstor.start_session(js.api_url)
      puts Jstor.public_info(js.api_url, fn, cookies)
   end

   desc "One time task to add external metadata system info for JSTOR"
   task :add_ext_sys  => :environment do
      puts "Adding external metadata system for JSTOR..."
      ExternalSystem.create(name: "JSTOR Forum", 
         public_url: "https://library.artstor.org", 
         api_url: "https://library.artstor.org/api")
   end

   def create_or_find_collection(title)
      xm  = XmlMetadata.find_by(title: title)
      if !xm.nil?
         puts "a collection of this name already exists. ID: #{xm.id}"
         return xm
      else
         xml = 
"<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<mods xmlns=\"http://www.loc.gov/mods/v3\"
      xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
      xmlns:mods=\"http://www.loc.gov/mods/v3\"
      xsi:schemaLocation=\"http://www.loc.gov/mods/v3
      http://www.loc.gov/standards/mods/v3/mods-3-3.xsd\">
   <titleInfo>
      <title>#{title}</title>
   </titleInfo>
</mods>"
         xm = XmlMetadata.create(desc_metadata: xml, availability_policy_id: 1, discoverability: false, 
            use_right_id: 1, dpla: false, ocr_hint_id: 2)
         puts "Create new JSTOR collection metadata record. ID: #{xm.id}"
         return xm
      end
   end

   desc "Second pass Link ALL artstor masterfiles to External metadata"
   task :pass2 => :environment do 
      puts "PASS 2: Linking all *ARCH* master files to matching Artstor external metadata"
      puts "Start Artstor session"
      js = ExternalSystem.find_by(name: "JSTOR Forum")
      cookies = Jstor.start_session(js.api_url)
      jstor_md = XmlMetadata.find_by(title: "UVA Library JSTOR Collection")
      
      puts "Finding all candidate master files"
      cnt = 0
      linked = 0
      MasterFile.where("metadata_id=?", jstor_md.id).find_each do |mf|
         cnt+=1
         js_key = mf.filename.split(".").first 
         as_info = Jstor.public_info(js.api_url, js_key, cookies)
         if as_info.blank? 
            next
         else
            uri = "/#/asset/#{as_info[:id]}"
            title = as_info[:title]
            puts "Master file #{mf.filename}[#{mf.id}] - ARTSTOR URI: #{uri}"
            em = ExternalMetadata.create!(external_system: js, external_uri: uri,
               use_right_id: 1, title: title, parent_metadata_id: jstor_md.id, 
               ocr_hint_id: 2, availability_policy_id:  1)
            mf.update!(metadata: em)  
            linked +=1 
         end 
         sleep(0.25)  
      end
      puts "DONE. Checked #{cnt} master files. Linked #{linked}"
   end

   desc "Link ALL artstor masterfiles to External metadata"
   task :link_all => :environment do 
      puts "Linking all *ARCH* master files to matching Artstor external metadata.."
      collection_md = XmlMetadata.find_by(title: "UVA Library JSTOR Collection")
      abort("Collection metadata not found") if collection_md.nil?

      puts "Start Artstor session"
      js = ExternalSystem.find_by(name: "JSTOR Forum")
      cookies = Jstor.start_session(js.api_url)
      
      puts "Finding all candidate master files"
      cnt = 0
      skip_cnt = 0
      MasterFile.where("filename like ?", "%arch%").find_each do |mf|
         unit = mf.unit
         next if !mf.metadata.nil? && mf.metadata_id != unit.metadata_id

         if unit.metadata.nil? 
            puts "==========> Unit #{unit.id} has no metadata; setting to JSTOR"
            unit.update!(metadata: collection_md)
         end

         js_key = mf.filename.split(".").first 
         as_info = Jstor.public_info(js.api_url, js_key, cookies)
         if as_info.blank? 
            puts "WARN: No public info found for #{js_key}"
            skip_cnt += 1
            next
         else
            uri = "/#/asset/#{as_info[:id]}"
            title = as_info[:title]
            puts "Master file #{mf.filename}[#{mf.id}] - ARTSTOR URI: #{uri}"
            em = ExternalMetadata.create!(external_system: js, external_uri: uri,
               use_right_id: 1, title: title, parent_metadata_id: unit.metadata_id, 
               ocr_hint_id: 2, availability_policy_id:  1)
            mf.update!(metadata: em)   
            cnt += 1
         end
      end
      puts "DONE ==============================================="
      puts "   #{cnt} masterfiles linked"
      puts "   #{skip_cnt} masterfiles not found in Artstor"
   end

   desc "Link a unit with no metadata to JSTOR"
   task :link_unit  => :environment do
      uid = ENV['unit']
      unit = Unit.find(uid)
      collection_md = XmlMetadata.find_by(title: "UVA Library JSTOR Collection")

      puts "Link all master files from unit #{unit.id} to JSTOR records"
      js = ExternalSystem.find_by(name: "JSTOR Forum")
      cookies = Jstor.start_session(js.api_url)

      linked = link_unit_to_as(unit, js, cookies, collection_md)
      puts "DONE. #{linked} master files updated"
   end

   desc "add jstor collection record to units in csv"
   task :fix_csv  => :environment do
      collection_md = XmlMetadata.find_by(title: "UVA Library JSTOR Collection")
      File.read("as_nomatch.csv").split("\n").each do |uid|
         unit = Unit.find(uid)
         if unit.metadata.nil?
            puts "===> Add JSTOR collection MD to Unit[#{uid}]"
            unit.update!(metadata: collection_md)
         end
      end
   end

   desc "Link units listed in csv to JSTOR"
   task :link_csv  => :environment do
      puts "Link all units in artstor_csv..."
      collection_md = XmlMetadata.find_by(title: "UVA Library JSTOR Collection")
      js = ExternalSystem.find_by(name: "JSTOR Forum")
      cookies = Jstor.start_session(js.api_url)
      cnt = 0
      File.read("artstor_units.csv").split("\n").each do |uid|
         puts "===> Link Unit[#{uid}]"
         linked = link_unit_to_as(Unit.find(uid), js, cookies, collection_md)
         puts "Unit #{uid}: #{linked} master files linked"
         cnt += 1
         if cnt % 25 == 0
            puts "requesting new auth cookies after 25 units"
            cookies = Jstor.start_session(js.api_url)
         end
         sleep(5)
      end   
   end

   def link_unit_to_as(unit, js, cookies, parent_md) 
      if unit.metadata.nil? 
         puts "==========> Unit #{unit.id} has no metadata; setting to Kore"
         unit.update!(metadata: parent_md)
      end
      cnt = 0
      unit.master_files.each do |mf| 
         js_key = mf.filename.split(".").first 
         as_info = Jstor.public_info(js.api_url, js_key, cookies)
         if as_info.blank? 
            puts "WARN: No public info found for #{js_key}"
            next
         else
            uri = "/#/asset/#{as_info[:id]}"
            title = as_info[:title]
            puts "Master file #{mf.filename}[#{mf.id}] - ARTSTOR URI: #{uri}"
            if mf.metadata.external_system_id != js.id
               puts "   creaing new metadata record"
               em = ExternalMetadata.create!(external_system: js, external_uri: uri,
                  use_right_id: 1, title: title, parent_metadata_id: parent_md.id, 
                  ocr_hint_id: 2, availability_policy_id:  1)
               mf.update!(metadata: em)  
               cnt +=1 
            else 
               if mf.metadata.external_uri == uri 
                  puts "   existing metadata correct. Nothing to do."
               else 
                  puts "   update existing metadata record"
                  mf.metadata.update( external_uri: uri, title: title)
                  cnt+=1
               end
            end
         end
      end
      return cnt
   end

   # generate the IIIF files for ARTSTOR masterfiles that lack them
   desc "publish all artstor masterfiles to IIIF"
   task :iiif  => :environment do
      puts "Publishing all missing IIIF files for *ARCH* master files..."
      cnt = 0
      missing_dirs = []
      MasterFile.where("filename like ?", "%arch%").find_each do |mf|
         if mf.iiif_exist? 
            #puts "MF #{mf.id} already has an IIIF JP2K file"
            next
         end

         # these files are only in the archive. Find them...
         # Note they are not archived by unit ID. Instead, they are archived 
         # by the part of the filename before the '_'
         unit_dir = mf.filename.split("_").first
         next if missing_dirs.include? unit_dir
         
         archive_dir = File.join(ARCHIVE_DIR, unit_dir)
         if !Dir.exist? archive_dir 
            puts "ERROR: Archive directory not found #{archive_dir}"
            missing_dirs << unit_dir
            next
         end

         archive_file = File.join(archive_dir, mf.filename)
         if !File.exist? archive_file 
            puts "ERROR: Archive file not found #{archive_file}"
            next
         end
         
         artstor_publish(archive_file, mf)
         cnt += 1
      end
      puts "Done. #{cnt} master files published to IIIF"
   end

   desc "publish/republish all masterfiles from an artstor unit"
   task :unit_iiif  => :environment do
      uid = ENV['unit']
      unit = Unit.find(uid)
      puts "Publishing all master files from unit #{unit.id}"
      cnt = 0
      unit.master_files.each do |mf|
         unit_dir = mf.filename.split("_").first
         archive_dir = File.join(ARCHIVE_DIR, unit_dir)
         if !Dir.exist? archive_dir 
            puts "ERROR: Archive directory not found #{archive_dir}"
            missing_dirs << unit_dir
            next
         end

         archive_file = File.join(archive_dir, mf.filename)
         if !File.exist? archive_file 
            puts "ERROR: Archive file not found #{archive_file}"
            next
         end
         
         artstor_publish(archive_file, mf, true)
         cnt += 1
      end
      puts "Done. #{cnt} master files published to IIIF"
   end

   def artstor_publish(orig_source, master_file, force = false) 
       source = orig_source
       # Generate a checksum if one does not already exist
       if master_file.md5.nil?
         source_md5 = Digest::MD5.hexdigest(File.read(source))
         master_file.update_attributes(:md5 => source_md5)
      end

      if master_file.filename.match(".tif$")
         # kakadu cant handle compression. remove it if detected
         cmd = "identify -quiet -ping -format '%C' #{source}[0]"
         compression = `#{cmd}`
         if compression != 'None'
            uncompressed_tmp = Tempfile.new([master_file.filename, ".tif"])
            dest_file = uncompressed_tmp.path
            cmd = "convert -compress none -quiet #{source} #{dest_file}"
            `#{cmd}`
            source = dest_file
            puts "MasterFile #{master_file.id} is compressed.  This has been corrected automatically. New source is #{source}"
         end
      end

      # set path to IIIF jp2k storage location
      jp2k_path = master_file.iiif_file()
      jp2kdir = File.dirname(jp2k_path)
      if !Dir.exist?(jp2kdir)
         FileUtils.mkdir_p jp2kdir 
      end

      if master_file.filename.match(".jp2$")
         # write a JPEG-2000 file to the destination directory
         FileUtils.copy(source, jp2k_path)
         puts "Copied JPEG-2000 image using '#{source}' as input file for the creation of deliverable '#{jp2k_path}'"

      elsif source.match(/\.tiff?$/) and File.file?(source)
         # If the JP2k already exists (and is not 0), don't make it again!
         if File.exist?(jp2k_path) && File.size(jp2k_path) > 0 && force == false
            puts "MasterFile #{master_file.id} already has JP2k file at #{jp2k_path}; skipping creation"
            return
         end

         # generate deliverables for DL use
         # As per a conversation with Ethan Gruber, I'm dividing the JP2K compression ratios between images that are greater and less than 500MB.
         executable = KDU_COMPRESS || %x( which kdu_compress ).strip
         if File.exist? executable
            cmd = "#{executable} -i #{source} -o #{jp2k_path} -rate 0.5 Clayers=1 Clevels=7"
            cmd << " \"Cprecincts={256,256},{256,256},{256,256},{128,128},{128,128},{64,64},{64,64},{32,32},{16,16}\""
            cmd << " \"Corder=RPCL\" \"ORGgen_plt=yes\" \"ORGtparts=R\" \"Cblk={64,64}\""
            cmd << " Cuse_sop=yes -quiet -num_threads 8"
            `#{cmd}`
            if !File.exist?(jp2k_path) || File.size(jp2k_path) == 0
               puts "ERROR: Destination #{jp2k_path} does not exist or is zero length"
            end
         else
            raise "kdu_compress missing"
         end

         puts "Generated JPEG-2000 image using '#{source}' as input file for the creation of deliverable '#{jp2k_path}'"
      else
         raise "Source is not a .tif or .jp2 file: #{source}"
      end
   end
end
