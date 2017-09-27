namespace :as do
   IIIF_USE_STATEMENT = "image-service-manifest"

   def get_auth_hdr(u,pw)
      as_root = "http://archives-test.lib.virginia.edu:8089"
      url = "#{Settings.archives_space_url}/users/#{u}/login"
      puts "API Auth URL: #{url}"
      resp = RestClient.post url, {password: pw}
      puts "got resp"
      json = JSON.parse(resp.body)
      session = json['session']

      # Make the rest header with session info to be used for all other requests
      hdr = {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}
      return hdr
   end

   def get_ao_detail(ao_uri, hdr, pid)
      existing_do = nil
      ao_detail = RestClient.get "#{Settings.archives_space_url}/#{ao_uri}", hdr
      ao_json = JSON.parse(ao_detail.body)
      ao_json['instances'].each do |instance|
         next if instance['instance_type'] != 'digital_object'
         do_uri = instance['digital_object']['ref']
         do_tree = RestClient.get "#{Settings.archives_space_url}/#{do_uri}", hdr
         do_json = JSON.parse(do_tree.body)
         return {ao_json: ao_json, do_exist: true} if do_json['digital_object_id'] == pid
      end
      return {ao_json: ao_json, do_exist: false}
   end

   def create_digital_object(repo_uri, hdr, tgt_ao, mf)
      pid = mf.metadata.pid
      payload = {
         digital_object_id: pid,
         title: mf.metadata.title,
         publish: true,
         file_versions: [
            {
               use_statement: IIIF_USE_STATEMENT,
               file_uri: "#{Settings.iiif_manifest_url}/#{pid}",
               publish: true
            }
         ]
      }

      digital_obj_id = -1
      begin
         resp = RestClient.post "#{Settings.archives_space_url}#{repo_uri}/digital_objects", "#{payload.to_json}", hdr
         if resp.code.to_i == 200
            json = JSON.parse(resp)
            digital_obj_id = json['id']
            puts "Digital object created. ID: #{json['id']}"
         else
            raise "Add digital object FAILED: #{resp.to_s}"
         end
      rescue RestClient::Exception => rce
         raise "*** ADD FAILED #{rce.response}"
      end

      # Add newly created digital object URI reference as an instance in the target archival object
      # and add a link back to tracksys metadata
      tgt_ao['instances'] << { instance_type: "digital_object", digital_object: { ref: "#{repo_uri}/digital_objects/#{digital_obj_id}"} }
      found = false
      tgt_ao['external_ids'].each do |ext|
         if ext['source'] == "tracksys"
            found = true
            puts "AO already has tracksys external ID. Not adding"
            break
         end
      end
      if found == false
         tgt_ao['external_ids'] << { source: "tracksys", external_id: "#{Settings.tracksys_url}/api/metadata/#{pid}?type=desc_metadata" }
      end

      begin
         resp = RestClient.post "#{Settings.archives_space_url}#{tgt_ao['uri']}", "#{tgt_ao.to_json}", hdr
         if resp.code.to_i == 200
            puts "Archival object updated"
         else
            raise "Archival object update FAILED: #{resp.to_s}"
         end
      rescue RestClient::Exception => rce
         raise "*** Archival object update FAILED #{rce.response}"
      end

      return digital_obj_id
   end

   # Make sure the image-service-manifest is present in the file versions use statment enum
   #
   desc "enums"
   task :enums  => :environment do
      u = ENV["u"]
      pw = ENV["p"]
      hdr = get_auth_hdr(u,pw)
      out = RestClient.get "#{Settings.archives_space_url}/config/enumerations", hdr
      found = false
      tgt_enum = nil
      JSON.parse(out.body).each do |rec|
         next if rec['name'] != 'file_version_use_statement'
         tgt_enum = rec
         rec['enumeration_values'].each do |ev|
            found = true if ev['value'] == IIIF_USE_STATEMENT
         end
      end

      if found
         puts "Enumeration value #{IIIF_USE_STATEMENT} EXISTS. Nothing to do"
      else
         puts "Enumeration value #{IIIF_USE_STATEMENT} does NOT exist. Adding..."
         last = tgt_enum['enumeration_values'].last
         last_pos = last['position']
         enum_id = last['enumeration_id']
         v = {enumeration_id: enum_id, value: IIIF_USE_STATEMENT, readonly: 0, position: last_pos+1, suppressed: false}
         tgt_enum['enumeration_values'] << v
         tgt_enum['values'] << IIIF_USE_STATEMENT
         begin
            resp = RestClient.post "#{Settings.archives_space_url}/config/enumerations/#{enum_id}", "#{tgt_enum.to_json}", hdr
            if resp.code.to_i == 200
               puts "#{IIIF_USE_STATEMENT} ADDED"
            else
               raise "Add #{IIIF_USE_STATEMENT} FAILED: #{resp.to_s}"
            end
         rescue RestClient::Exception => rce
            raise "*** ADD FAILED #{rce.response}"
         end
      end
   end

   # Link The Eduardo Montes-Bradley Photograph and Film Collection metadata to archivesspace
   # rake as:hs u=admin p=admin metadata=58576
   #
   desc "hs"
   task :hs  => :environment do
      u = ENV["u"]
      pw = ENV["p"]
      id = ENV['metadata']
      metadata = Metadata.find(id)
      puts "Source Metadata: #{metadata.title}"
      hdr = get_auth_hdr(u,pw)

      # 7 = health sciences, 210 = eduardo photos. List all stuff under it and find children
      repo_uri = "/repositories/7"
      repo_url = "#{Settings.archives_space_url}#{repo_uri}"
      out = RestClient.get "#{repo_url}/resources/210/tree", hdr
      json = JSON.parse(out.body)

      # run through all masterfiles associated with the  Eduardo Montes-Bradley metadata
      metadata.units.each do |u|
         puts "Getting master files for unit #{u.id}"
         u.master_files.each do |mf|
            puts "Looking for AS match for #{mf.title}"

            # in this case, the MF title contains the original filename. Format: montesbradley000NN.tif
            # where NN is the image number. Pull this out as it will be used to match archival_object
            # indicator_1 below
            tgt_id = mf.title.gsub(/\D/,'').to_i

            json['children'].each do |c|
               next if c['node_type'] != 'archival_object'

               uri = c['record_uri']
               id = c['containers'][0]['indicator_1'].to_i
               if id == tgt_id
                  # Match found. Look at all of the details of the object to
                  # see if it already has a tracksys digital object associated.
                  # Do this by iterating over the 'instances' object and Looking
                  # for ones that are instance_type digital_object
                  puts "===============MATCH: #{c['title']}, #{uri} ID=#{id}"
                  ao_info = get_ao_detail(uri, hdr, mf.metadata.pid)
                  if ao_info[:do_exist]
                     puts "ERROR: Digital object already exists for the master file. Skipping"
                  else
                     puts "Creating new digitial object..."
                     do_id = create_digital_object(repo_uri, hdr, ao_info[:ao_json], mf)
                     mf.metadata.update(supplemental_system: "ArchivesSpace", supplemental_uri: "/digital_objects/#{do_id}")
                  end
               end
            end
         end
      end
      puts "DONE"
   end

   desc "va photos ingest"
   task :va_photos  => :environment do
      id = ENV['id']
      abort("id is required") if id.nil?
      unit = Unit.find(id)

      hdr = get_auth_hdr(Settings.as_user, Settings.as_pass)

      # 3 = UVA SC, 413 = VA photos. List all stuff under it and find children
      repo_uri = "/repositories/3"
      repo_url = "#{Settings.archives_space_url}#{repo_uri}"
      out = RestClient.get "#{repo_url}/resources/413/tree", hdr
      json = JSON.parse(out.body)

      # Get all of the masterfiles
      curr_metadata = nil
      unit.master_files.each do |mf|
         # don't care about the flip side of the photos. These are titled 2
         next if mf.title == "2"

         # A description is the start of a new folder. detect
         # and reset the current metadata.
         if !mf.description.blank?
            curr_metadata = nil

            # MF desc has photographs - at front. Toss it.
            # After that, we can match AS if the first word matches
            mf_folder_name = mf.description.split("-")[1].strip
            mf_folder_name = mf_folder_name.split(" ")[0].strip
            json['children'].each do |child|
               next if child['node_type'] != 'archival_object'

               test = child['title'].split(" ")[0].strip
               if test == mf_folder_name
                  puts "===> AO MATCH #{child.to_json}"
                  # NOTE: record_uri is something like: /repositories/3/archival_objects/53541
                  # basically a full reference to the archival object that contains the
                  # relevant metadata describing the DO that will be created below
                  ao_detail = get_ao_detail( child['record_uri'], hdr, mf.metadata.pid)
                  if ao_detail[:do_exist]
                     puts "AS Digital Object already exists"
                  else
                     puts "AS Digital Object does not exist"

                     # see if MF metadata is external. Create new instance
                     # if one doesn't exist. After this save a reference to the
                     # external metatdata object as it will be assiciated with
                     # each subsequent master file (until a new description is found)
                     if mf.metadata.type != "ExternalMetadata"
                        puts "Creating new TrackSys external metadata object"
                        curr_metadata = ExternalMetadata.create(title: mf.description, is_approved: true,
                           external_system: "ArchivesSpace", use_right: mf.metadata.use_right)
                        mf.update(metadata: curr_metadata)
                     else
                        puts "Using existing metadata #{mf.metadata.id}"
                        curr_metadata = mf.metadata
                     end

                     puts "Creating new AS Digital Object..."
                     do_id = create_digital_object(repo_uri, hdr, ao_detail[:ao_json], mf)
                     mf.metadata.update(supplemental_system: "ArchivesSpace", supplemental_uri: child['record_uri'])
                  end
               end
            end
         else
            # This MF occurrs after one with a description set
            # the metadata should already extist and be tied to
            # and ArchivesSpace DO. Just tie the curr_metadata to this MF
            if mf.metadata.id != curr_metadata.id
               puts "Updating master file to point to folder-level external metadata"
               mf.update(metadata: curr_metadata)
            end
         end
      end
   end

   desc "Test authentication with AS API"
   task :test_auth  => :environment do
      begin
         hdr = get_auth_hdr(Settings.as_user, Settings.as_pass)
         puts hdr
      rescue Exception=> e
         puts "FAIL: #{e.to_json}"
      end
   end
end
