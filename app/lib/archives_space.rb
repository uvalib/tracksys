module ArchivesSpace
   def self.get_auth()
      url = "#{Settings.as_api_url}/users/#{Settings.as_user}/login"
      puts "API Auth URL: #{url}"
      resp = RestClient.post url, {password: Settings.as_pass}
      json = JSON.parse(resp.body)
      return json['session']
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

   def self.create_digital_object(auth, tgt_obj, pid, title)
      payload = {
         digital_object_id: pid,
         title: title,
         publish: true,
         file_versions: [
            {
               use_statement:  "image-service-manifest",
               file_uri: "#{Settings.iiif_manifest_url}/#{pid}",
               publish: true
            }
         ]
      }
   end

   def self.auth_header(session)
      return {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}
   end
   private_class_method :auth_header
end
