namespace :as do
   AS_ROOT = "http://archives-test.lib.virginia.edu:8089"
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

   desc "hs"
   task :hs  => :environment do
      u = ENV["u"]
      pw = ENV["p"]
      id = ENV['metadata']
      metadata = Metadata.find(id)
      puts "Source Metadata: #{metadata.title}"

      hdr = get_auth_hdr(u,pw)
      # 7 = health sciences, 210 = eduardo photos. List all stuff under it and find childrem
      out = RestClient.get "#{AS_ROOT}/repositories/7/resources/210/tree", hdr
      json = JSON.parse(out.body)

      metadata.units.each do |u|
         u.master_files.each do |mf|
            puts "Looking for AS match for #{mf.title}"
            # in this case, the title contains the original filename. Format: montesbradley000NN.tif
            # where NN is the image number. Pull this out as it will be used to match archival_object
            # indicator_1 below
            tgt_id = mf.title.gsub(/\D/,'').to_i

            json['children'].each do |c|
               if c['node_type'] != 'archival_object'
                  uri = c['record_uri']
                  id = c['containers'][0]['indicator_1'].to_i
                  if id == tgt_id
                     puts c
                     puts "===============MATCH: #{c['title']}, #{uri} ID=#{id}"
                     ao_detail = RestClient.get "#{AS_ROOT}/#{uri}", hdr
                     puts ao_detail
                  end
               else
                  puts c
               end
            end
         end
      end
   end

   desc "test"
   task :test  => :environment do
      u = ENV["u"]
      pw = ENV["p"]
      r = ENV["r"]

      # first call to get a session for the specified user
      as_root = "http://archives-test.lib.virginia.edu:8089"
      url = "#{as_root}/users/#{u}/login"
      resp = RestClient.post url, {password: pw}
      json = JSON.parse(resp.body)
      session = json['session']
      puts session

      # Make the rest header with session info to be used for all other requests
      hdr = {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}

      # Find URI for resporce specified
      out = RestClient.get "#{as_root}/repositories", hdr
      repo_uri = ""
      JSON.parse(out.body).each do |repo|
         if repo['name'] == r
            repo_uri = repo['uri']
            break
         end
      end

      # Get ALL archival objects for the repo
      out = RestClient.get "#{as_root}#{repo_uri}/archival_objects?all_ids=true", hdr
      aos = JSON.parse(out.body)

      # Walk IDS and pick FIRST item for digital object addition
      # Assumed structure:
      #  collection
      #     series (archival object, level = series)
      #       item (archival object, level = item )
      #          digital object
      tgt_ao = nil
      aos.each do |id|
         out = RestClient.get "#{as_root}#{repo_uri}/archival_objects/#{id}", hdr
         ao = JSON.parse(out.body)
         next if ao['level'] != "item"
         tgt_ao = ao
         break
      end
      puts "Found target AO: \"#{tgt_ao['title']}\": #{tgt_ao['uri']}"

      payload = {
         digital_object_id: "tsi:12",
         title: "Digital object for 1st letter",
         publish: true,
         file_versions: [
            {file_uri: "http://tracksysdev.lib.virginiaedu:8080/uva-lib:2137592", publish: true}
         ]
      }
      puts "Create Digital Object #{payload.to_json}"
      digital_obj_id = -1
      begin
         resp = RestClient.post "#{as_root}#{repo_uri}/digital_objects", "#{payload.to_json}", hdr
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
      tgt_ao['instances'] << { instance_type: "digital_object", digital_object: { ref: "#{repo_uri}/digital_objects/#{digital_obj_id}"} }
      puts "UPDATE AO WITH: #{tgt_ao.to_json}"
      begin
         resp = RestClient.post "#{as_root}#{tgt_ao['uri']}", "#{tgt_ao.to_json}", hdr
         if resp.code.to_i == 200
            puts "Archival object updated"
         else
            raise "Archival object update FAILED: #{resp.to_s}"
         end
      rescue RestClient::Exception => rce
         raise "*** Archival object update FAILED #{rce.response}"
      end

      # # Get ALL Digital objects for the repo. Can be used to get JSON structure of object
      # out = RestClient.get "#{as_root}#{repo_uri}/digital_objects?all_ids=true", hdr
      # dos = JSON.parse(out.body)
      # puts "DIGITAL OBJECTS ==========================="
      # dos.each do |id|
      #    out = RestClient.get "#{as_root}#{repo_uri}/digital_objects/#{id}", hdr
      #    dobj = JSON.parse(out.body)
      #    puts "#{dobj.to_json} ==============================\n\n"
      # end
   end
end
# {"title":"Fern Campbell, 2012","id":45171,"record_uri":"/repositories/7/archival_objects/45171","publish":false,"suppressed":false,"node_type":"archival_object","level":"item","instance_types":["Graphic Materials","digital_object"],
#    "containers":[{"type_1":"object","indicator_1":"1","type_2":null,"indicator_2":null,"type_3":null,"indicator_3":null}],"has_children":false,"children":[]}
# {"title":"Stuart S. Howards, 2012","id":45177,"record_uri":"/repositories/7/archival_objects/45177","publish":false,"suppressed":false,"node_type":"archival_object","level":"item","instance_types":["graphic_materials","digital_object"],"containers":[{"type_1":"object","indicator_1":"6","type_2":null,"indicator_2":null,"type_3":null,"indicator_3":null}],"has_children":false,"children":[]}
# {"title":"Stuart S. Howards, 2013","id":45187,"record_uri":"/repositories/7/archival_objects/45187","publish":false,"suppressed":false,"node_type":"archival_object","level":"item","instance_types":["graphic_materials","digital_object"],"containers":[{"type_1":"object","indicator_1":"8","type_2":null,"indicator_2":null,"type_3":null,"indicator_3":null}],"has_children":false,"children":[]}
