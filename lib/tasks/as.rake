namespace :as do
   AS_ROOT = "http://archives-test.lib.virginia.edu:8089"
   # IIIF_USE_STATEMENT = "image-service-manifest"
   IIIF_USE_STATEMENT = "image-service"

   def get_auth_hdr(u,pw)
      as_root = "http://archives-test.lib.virginia.edu:8089"
      url = "#{AS_ROOT}/users/#{u}/login"
      resp = RestClient.post url, {password: pw}
      json = JSON.parse(resp.body)
      session = json['session']

      # Make the rest header with session info to be used for all other requests
      hdr = {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}
      return hdr
   end

   def get_ao_detail(ao_uri, hdr, pid)
      existing_do = nil
      ao_detail = RestClient.get "#{AS_ROOT}/#{ao_uri}", hdr
      ao_json = JSON.parse(ao_detail.body)
      ao_json['instances'].each do |instance|
         next if instance['instance_type'] != 'digital_object'
         do_uri = instance['digital_object']['ref']
         do_tree = RestClient.get "#{AS_ROOT}/#{do_uri}", hdr
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
         resp = RestClient.post "#{AS_ROOT}#{repo_uri}/digital_objects", "#{payload.to_json}", hdr
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
      tgt_ao['external_ids'] << { source: "tracksys", external_id: "#{Settings.tracksys_url}/api/metadata/#{pid}?type=desc_metadata" }
      begin
         resp = RestClient.post "#{AS_ROOT}#{tgt_ao['uri']}", "#{tgt_ao.to_json}", hdr
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

   # Link The Eduardo Montes-Bradley Photograph and Film Collection metadata to archivesspace
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
      repo_url = "#{AS_ROOT}#{repo_uri}"
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

   # desc "test"
   # task :test  => :environment do
   #    u = ENV["u"]
   #    pw = ENV["p"]
   #    r = ENV["r"]
   #
   #    # first call to get a session for the specified user
   #    as_root = "http://archives-test.lib.virginia.edu:8089"
   #    url = "#{as_root}/users/#{u}/login"
   #    resp = RestClient.post url, {password: pw}
   #    json = JSON.parse(resp.body)
   #    session = json['session']
   #    puts session
   #
   #    # Make the rest header with session info to be used for all other requests
   #    hdr = {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}
   #
   #    # Find URI for resporce specified
   #    out = RestClient.get "#{as_root}/repositories", hdr
   #    repo_uri = ""
   #    JSON.parse(out.body).each do |repo|
   #       if repo['name'] == r
   #          repo_uri = repo['uri']
   #          break
   #       end
   #    end
   #
   #    # Get ALL archival objects for the repo
   #    out = RestClient.get "#{as_root}#{repo_uri}/archival_objects?all_ids=true", hdr
   #    aos = JSON.parse(out.body)
   #
   #    # Walk IDS and pick FIRST item for digital object addition
   #    # Assumed structure:
   #    #  collection
   #    #     series (archival object, level = series)
   #    #       item (archival object, level = item )
   #    #          digital object
   #    tgt_ao = nil
   #    aos.each do |id|
   #       out = RestClient.get "#{as_root}#{repo_uri}/archival_objects/#{id}", hdr
   #       ao = JSON.parse(out.body)
   #       next if ao['level'] != "item"
   #       tgt_ao = ao
   #       break
   #    end
   #    puts "Found target AO: \"#{tgt_ao['title']}\": #{tgt_ao['uri']}"
   #
   #    payload = {
   #       digital_object_id: "tsi:12",
   #       title: "Digital object for 1st letter",
   #       publish: true,
   #       file_versions: [
   #          {file_uri: "http://tracksysdev.lib.virginiaedu:8080/uva-lib:2137592", publish: true}
   #       ]
   #    }
   #    puts "Create Digital Object #{payload.to_json}"
   #    digital_obj_id = -1
   #    begin
   #       resp = RestClient.post "#{as_root}#{repo_uri}/digital_objects", "#{payload.to_json}", hdr
   #       if resp.code.to_i == 200
   #          json = JSON.parse(resp)
   #          digital_obj_id = json['id']
   #          puts "Digital object created. ID: #{json['id']}"
   #       else
   #          raise "Add digital object FAILED: #{resp.to_s}"
   #       end
   #    rescue RestClient::Exception => rce
   #       raise "*** ADD FAILED #{rce.response}"
   #    end
   #
   #    # Add newly created digital object URI reference as an instance in the target archival object
   #    tgt_ao['instances'] << { instance_type: "digital_object", digital_object: { ref: "#{repo_uri}/digital_objects/#{digital_obj_id}"} }
   #    puts "UPDATE AO WITH: #{tgt_ao.to_json}"
   #    begin
   #       resp = RestClient.post "#{as_root}#{tgt_ao['uri']}", "#{tgt_ao.to_json}", hdr
   #       if resp.code.to_i == 200
   #          puts "Archival object updated"
   #       else
   #          raise "Archival object update FAILED: #{resp.to_s}"
   #       end
   #    rescue RestClient::Exception => rce
   #       raise "*** Archival object update FAILED #{rce.response}"
   #    end
   #
   #    # # Get ALL Digital objects for the repo. Can be used to get JSON structure of object
   #    # out = RestClient.get "#{as_root}#{repo_uri}/digital_objects?all_ids=true", hdr
   #    # dos = JSON.parse(out.body)
   #    # puts "DIGITAL OBJECTS ==========================="
   #    # dos.each do |id|
   #    #    out = RestClient.get "#{as_root}#{repo_uri}/digital_objects/#{id}", hdr
   #    #    dobj = JSON.parse(out.body)
   #    #    puts "#{dobj.to_json} ==============================\n\n"
   #    # end
   # end
end
