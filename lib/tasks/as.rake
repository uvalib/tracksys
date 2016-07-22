namespace :as do
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

      # Make the rest header with session info to be used for all other requests
      hdr = {:content_type => :json, :accept => :json, :'X-ArchivesSpace-Session'=>session}

      # example; find URI for resporce specified
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

      puts "Create Digital Object in: AO \"#{tgt_ao['title']}\": #{tgt_ao['uri']}"

      payload = {
         digital_object_id: "tsi:12",
         title: "Digital object for 1st letter",
         publish: true,
         file_versions: [
            {file_uri: "http://tracksysdev.lib.virginia.edu:8080/uva-lib:2137592", publish: true}
         ],
         linked_instances: [ {ref: tgt_ao['uri'] } ],
         repository: { ref: repo_uri}
      }

      # CREATE responses:
      # 200 – {:status => “Created”, :id => (id of created object), :warnings => {(warnings)}}
      # 400 – {:error => (description of error)}

      # # Get ALL Digital objects for the repo. Used to get JSON structure of object. Listed at end of file
      # out = RestClient.get "#{as_root}#{uri}/digital_objects?all_ids=true", hdr
      # dos = JSON.parse(out.body)
      # puts "DIGITAL OBJECTS ==========================="
      # dos.each do |id|
      #    out = RestClient.get "#{as_root}#{uri}/digital_objects/#{id}", hdr
      #    dobj = JSON.parse(out.body)
      #    puts "#{dobj.to_json} ==============================\n\n"
      # end
   end

   #GET /repositories/:repo_id/archival_objects/:id
end

# EXAMPLE Digital Object JSON:
# {
# 	"lock_version": 1,
# 	"digital_object_id": "tsi:11",
# 	"title": "Digital object for 4th letter",
# 	"publish": true,
# 	"restrictions": false,
# 	"created_by": "admin",
# 	"last_modified_by": "admin",
# 	"create_time": "2016-07-22T19:15:47Z",
# 	"system_mtime": "2016-07-22T19:15:54Z",
# 	"user_mtime": "2016-07-22T19:15:47Z",
# 	"suppressed": false,
# 	"jsonmodel_type": "digital_object",
# 	"external_ids": [],
# 	"subjects": [],
# 	"linked_events": [],
# 	"extents": [],
# 	"dates": [],
# 	"external_documents": [],
# 	"rights_statements": [],
# 	"linked_agents": [],
# 	"file_versions": [{
# 		"lock_version": 0,
# 		"file_uri": "http://tracksysdev.lib.virginia.edu:8080/uva-lib:2137592",
# 		"publish": true,
# 		"created_by": "admin",
# 		"last_modified_by": "admin",
# 		"create_time": "2016-07-22T19:15:47Z",
# 		"system_mtime": "2016-07-22T19:15:47Z",
# 		"user_mtime": "2016-07-22T19:15:47Z",
# 		"jsonmodel_type": "file_version",
# 		"identifier": "3"
# 	}],
# 	"notes": [],
# 	"linked_instances": [{
# 		"ref": "/repositories/9/archival_objects/39750"
# 	}],
# 	"uri": "/repositories/9/digital_objects/3",
# 	"repository": {
# 		"ref": "/repositories/9"
# 	},
# 	"tree": {
# 		"ref": "/repositories/9/digital_objects/3/tree"
# 	}
# }
