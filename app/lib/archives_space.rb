module ArchivesSpace
   # Authenticate withthe ArchivesSpace API and get a session auth token
   # that will be used in all subsequent requests. This is not permanant and shouldn't be cached
   #
   def self.get_auth_session()
      url = "#{Settings.as_api_url}/users/#{Settings.as_user}/login"
      resp = RestClient.post url, {password: Settings.as_pass}
      json = JSON.parse(resp.body)
      return json['session']
   end

   # Lookup some brief info for the given AS public URL
   #
   def self.lookup(as_url)
      auth = get_auth_session()
      as_info = parse_public_url(as_url)
      repo = get_repository(auth, as_info[:repo])
      tgt_obj = nil
      if as_info[:parent_type] == "resources"
         tgt_obj = get_resource(auth, as_info[:repo], as_info[:parent_id])
      elsif as_info[:parent_type] == "archival_objects"
         tgt_obj = get_archival_object(auth, as_info[:repo], as_info[:parent_id])
      else
         raise("Unsupported parent type: #{as_info[:parent_type] }")
      end

      out = {
         repository: repo['name'],
         title: tgt_obj['title'],
         id: tgt_obj['id_0'],
         uri: tgt_obj['uri']
      }

      # if this has ancestors, it is part of a collection. Find the collection info
      if !tgt_obj['ancestors'].nil?
         tgt_obj['ancestors'].each do |ancestor|
            if ancestor['level'] == "collection"
               bits = ancestor['ref'].split("/")
               coll_obj = get_resource(auth, bits[2], bits[4])
               out[:collection] = coll_obj['finding_aid_title']
               out[:id] = coll_obj['id_0']
               break
            end
         end
      end
      return out
   end

   # Create a link between the specified unit and ArchivesSpace object. The parent metadata
   # for the unit will be converted to ExternalMetadata and contain the linkage
   #
   def self.link(unit_id, as_url, publish, log = Logger.new(STDOUT) )
      log.info "Link TrackSys Unit #{unit_id} to #{as_url}"
      unit = Unit.find(unit_id)
      as_info = parse_public_url(as_url)
      auth = get_auth_session()

      tgt_obj = nil
      if as_info[:parent_type] == "resources"
         log.info "Looking up parent resource #{as_info[:parent_id]} in repo #{as_info[:repo]}..."
         tgt_obj = get_resource(auth, as_info[:repo], as_info[:parent_id])
      elsif as_info[:parent_type] == "archival_objects"
         log.info "Looking up parent archival object #{as_info[:parent_id]} in repo #{as_info[:repo]}..."
         tgt_obj = get_archival_object(auth, as_info[:repo], as_info[:parent_id])
      else
         raise("Unsupported parent type: #{as_info[:parent_type] }")
      end

      if tgt_obj.nil?
         raise("#{as_info[:parent_type]}:#{as_info[:parent_id]} not found in repo #{as_info[:repo]}")
      end
      if has_digital_object?(auth, tgt_obj, unit.metadata.pid)
         log("#{as_info[:parent_type]}:#{as_info[:parent_id]} already has digital object. Use existing.")
      else
         log.info "Creating digitial object for PID #{unit.metadata.pid}"
         create_digital_object(auth, tgt_obj, unit.metadata, publish)
      end

      if unit.metadata.type != "ExternalMetadata"
         log.info "Converting existing metadata record to ExternalMetadata"
         # Change type fitst, then reload so it changes to ExtMetadata
         # and can handle blanking out many of the other fields
         unit.metadata.update!(type: "ExternalMetadata")
         unit = Unit.find(unit_id)
         ext_uri = "/repositories/#{as_info[:repo]}/#{as_info[:parent_type]}/#{as_info[:parent_id]}"
         unit.metadata.update!(creator_name: nil, catalog_key: nil, barcode: nil,
            call_number:nil, external_system: "ArchivesSpace", external_uri: ext_uri)
      end

      log.info "ArchivesSpace link successfully created"
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
         else
            raise "ArchivesSpace create DigitalObject API response code #{resp.code}: #{resp.to_s}"
         end
      rescue RestClient::Exception => rce
         err_body = JSON.parse(rce.response.body)
         raise "Add DigitalObject FAILED: #{err_body['error']}"
      end

      # Add newly created digital object URI reference as an instance in the target archival object
      tgt_obj['instances'] << {
         instance_type: "digital_object",
         digital_object: { ref: "#{repo_uri}/digital_objects/#{digital_obj_id}"}
      }
      begin
         url = "#{Settings.as_api_url}#{tgt_obj['uri']}"
         resp = RestClient.post "#{Settings.as_api_url}#{tgt_obj['uri']}", "#{tgt_obj.to_json}", auth_header(auth)
         if resp.code.to_i != 200
            raise "ArchivesSpace update parent API response code #{resp.code}: #{resp.to_s}"
         end
      rescue RestClient::Exception => rce
         err_body = JSON.parse(rce.response.body)
         raise "Parent object update FAILED: #{err_body['error']}"
      end
   end

   def self.auth_header(session)
      return {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}
   end
end
