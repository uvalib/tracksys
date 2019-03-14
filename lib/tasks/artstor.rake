namespace :artstor do
   desc "One time task to add external metadata system info for JSTOR"
   task :add_ext_sys  => :environment do
      puts "Adding external metadata system for JSTOR..."
      ExternalSystem.create(name: "JSTOR", 
         public_url: "https://library.artstor.org", 
         api_url: "https://forum.jstor.org")
   end

   # NOTES: all belong to the Kore collection. Make an XML metadata record as 
   # a collection placeholder. Each MF gets its own ExternalMetadata reference 
   # to the public interface (if it is available)
   # 16414
   desc "Link a unit with no metadata to JSTOR"
   task :link   => :environment do
      uid = ENV['unit']
      abort("Unit is required") if uid.blank?
      unit = Unit.find(uid)
      abort("Unit #{uid} already has metadata") if !unit.metadata.nil?
      puts "Link unit #{uid} to JSTOR"
      js = ExternalSystem.find_by(name: "JSTOR")
      jstor_cookies = jstorLogin(js)

      unit.master_files.each do |mf| 
         js_key = unit.master_files.first.filename.split(".").first 
         puts "Check for JSTOR ID[#{js_key}]"
         p  = {type: "string", field: "filename", fieldName: "Filename", value: js_key}.to_json
         p = p.gsub(/\"/, "%22").gsub(/{/,"%7B").gsub(/}/, "%7D")
         f = "filter=[#{p}]"
         q = "#{js.api_url}/projects/64/assets?with_meta=false&start=0&limit=1&sort=id&dir=DESC&#{f}"
         resp = RestClient.get(q,{cookies: jstor_cookies})
         if resp.code != 200
            puts "ERROR: JSTOR requst for #{js_key} FAILED - #{resp.code}:#{resp.body}"
            next
         end
         json = JSON.parse(resp.body)
         if json['total'] == 0 
            puts "No item found for #{js_key}"
            next
         end
         if json['total'] > 1 
            puts "WARN: Too many matches (#{json['total']}) found for #{js_key}"
            next
         end

         puts "Found"
         break
      end
      puts "DONE"
   end

   def jstorLogin(js)
      puts "authenticating with JSTOR..."
      form = {email: Settings.jstor_email, password: Settings.jstor_pass}
      resp = RestClient.post("#{js.api_url}/account", form)
      if resp.code != 200 
         raise "JSTOR authentication failed: #{resp.body}"
      end
      puts "Successfully authenticated"
      resp.cookie_jar.cookies
   end

   # generate the IIIF files for ARTSTOR masterfiles that lack them
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

   def artstor_publish(orig_source, master_file) 
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
            cmd = "convert -compress none #{source} #{dest_file}"
            puts "Fixing compression with #{cmd}"
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
         if File.exist?(jp2k_path) && File.size(jp2k_path) > 0
            puts "MasterFile #{master_file.id} already has JP2k file at #{jp2k_path}; skipping creation"
            return
         end

         # generate deliverables for DL use
         # As per a conversation with Ethan Gruber, I'm dividing the JP2K compression ratios between images that are greater and less than 500MB.
         executable = KDU_COMPRESS || %x( which kdu_compress ).strip
         if File.exist? executable
            `#{executable} -i #{source} -o #{jp2k_path} -rate 1.0,0.5,0.25 -num_threads #{NUM_JP2K_THREADS}`
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
