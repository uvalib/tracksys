module ArchivesSpace
   def self.get_auth_session()
      url = "#{Settings.as_api_url}/users/#{Settings.as_user}/login"
      puts "API Auth URL: #{url}"
      resp = RestClient.post url, {password: Settings.as_pass}
      json = JSON.parse(resp.body)
      return json['session']
   end

   def self.link(unit_id, as_url, publish)
      puts "Link TrackSys Unit #{unit_id} to #{as_url}"
      unit = Unit.find(unit_id)
      metadata_pid = unit.metadata.pid
      as_info = parse_public_url(as_url)
      auth = get_auth_session
      tgt_obj = nil
      if as_info[:parent_type] == "resources"
         puts "Looking up parent resource #{as_info[:parent_id]} in repo #{as_info[:repo]}..."
         tgt_obj = get_resource(auth, as_info[:repo], as_info[:parent_id])
      elsif as_info[:parent_type] == "archival_objects"
         puts "Looking up parent archival object #{as_info[:parent_id]} in repo #{as_info[:repo]}..."
         tgt_obj = get_archival_object(auth, as_info[:repo], as_info[:parent_id])
      else
         abort("Unsupported parent type: #{as_info[:parent_type] }")
      end

      if tgt_obj.nil?
         abort("#{as_info[:parent_type]}:#{as_info[:parent_id]} not found in repo #{as_info[:repo]}")
      end
      if has_digital_object?(auth, tgt_obj, metadata_pid)
         puts("#{as_info[:parent_type]}:#{as_info[:parent_id]} already has digital object. Use existing.")
      else
         puts "Creating digitial object for PID #{metadata_pid}"
         create_digital_object(auth, tgt_obj, unit.metadata, publish)
      end

      puts "Convert existing metadata record to external"
      # Change type fitst, then reload so it changes to ExtMetadata
      # and can handle blanking out many of the other fields
      unit.metadata.update!(type: "ExternalMetadata")
      unit = Unit.find(unit_id)
      ext_uri = "/repositories/#{as_info[:repo]}/#{as_info[:parent_type]}/#{as_info[:parent_id]}"
      unit.metadata.update!(creator_name: nil, catalog_key: nil, barcode: nil,
         call_number:nil, external_system: "ArchivesSpace", external_uri: ext_uri)

      puts "DONE!"
   end

   def self.parse_public_url(url)
      # public AS urls look like this:
      #    https://archives.lib.virginia.edu/repositories/3/archival_objects/62839
      # only care about the repoID, object type and objID
      bits = url.split("/")
      return { repo: bits[4], parent_type: bits[5], parent_id: bits.last}
   end

   def self.get_repositories(auth)
      repo_url = "#{Settings.as_api_url}/repositories"
      out = RestClient.get repo_url, auth_header(auth)
      json = JSON.parse(out.body)
      out = []
      json.each do |repo|
         out << {name: repo['name'], id: repo['uri'].split("/").last}
      end
      return out
   end

   def self.get_repository(auth, repo_id)
      repo_url = "#{Settings.as_api_url}/repositories/#{repo_id}"
      out = RestClient.get repo_url, auth_header(auth)
      return JSON.parse(out.body)
   end

   def self.get_resource(auth, repo_id, resource_id)
      url = "#{Settings.as_api_url}/repositories/#{repo_id}/resources/#{resource_id}"
      out = RestClient.get url, auth_header(auth)
      return JSON.parse(out.body)
   end

   def self.get_archival_object(auth, repo_id, ao_id)
      url = "#{Settings.as_api_url}/repositories/#{repo_id}/archival_objects/#{ao_id}"
      out = RestClient.get url, auth_header(auth)
      return JSON.parse(out.body)
   end

   def self.get_digital_object(auth, repo_id, do_id)
      url = "#{Settings.as_api_url}/repositories/#{repo_id}/digital_objects/#{do_id}"
      out = RestClient.get url, auth_header(auth)
      json =  JSON.parse(out.body)
      return {pid: json['digital_object_id'], title: json['title'], iiif: json['file_versions'].first['file_uri']}
   end

   def self.has_digital_object?(auth, as_json, pid)
      as_json['instances'].each do |inst|
         next if inst['digital_object'].nil?
          # format /repositories/REPO_ID/digital_objects/DO_ID
         ref = inst['digital_object']['ref']
         bits = ref.split("/")
         repo_id = bits[2]
         do_id = bits.last
         dobj = get_digital_object(auth, repo_id, do_id)
         return true if dobj[:pid] == pid
      end
      return false
   end

   def self.create_digital_object(auth, tgt_obj, ts_metadata, publish)
      payload = {
         digital_object_id: ts_metadata.pid,
         title: ts_metadata.title,
         publish: publish,
         file_versions: [
            {
               use_statement:  "image-service-manifest",
               file_uri: "#{Settings.iiif_manifest_url}/#{ts_metadata.pid}",
               publish: true
            }
         ]
      }

      repo_uri = tgt_obj['repository']['ref']
      digital_obj_id = -1

      begin
         resp = RestClient.post "#{Settings.as_api_url}#{repo_uri}/digital_objects", "#{payload.to_json}", auth_header(auth)
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
      tgt_obj['instances'] << {
         instance_type: "digital_object",
         digital_object: { ref: "#{repo_uri}/digital_objects/#{digital_obj_id}"}
      }
      begin
         resp = RestClient.post "#{Settings.as_api_url}#{tgt_obj['uri']}", "#{tgt_obj.to_json}", auth_header(auth)
         if resp.code.to_i == 200
            puts "Parent object updated"
         else
            raise "Parent object update FAILED: #{resp.to_s}"
         end
      rescue RestClient::Exception => rce
         raise "*** Archival object update FAILED #{rce.response}"
      end
   end

   def self.auth_header(session)
      return {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}
   end
end
