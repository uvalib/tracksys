module Jstor 
   # Start an Artstor public sesssion and return cookies
   #
   def self.start_session ( api_url )
      puts "Starting Artstor public session..."
      resp = RestClient.get("#{api_url}/secure/userinfo")
      if resp.code != 200 
         raise "JSTOR authentication failed: #{resp.body}"
      end
      puts "Successfully authenticated to puiblic ARTSTOR API"
      resp.cookie_jar.cookies
   end

   # Search the ArtStor public API by filename
   #
   def self.public_info(api_url, filename, cookies)
      puts "Find public ID for #{filename}"
      params = {limit: 1, start: 0, content_types: ["art"], query: "#{filename}"}
      resp = RestClient.post("#{api_url}/search/v1.0/search", 
         params.to_json, {content_type: :json, authority: "library.artstor.org", cookies: cookies})
      if resp.code != 200 
         puts "No public ID found. Code #{resp.code}:#{resp.body}"
         return {}
      end

      json = JSON.parse(resp.body)
      if json['results'].length == 0
         puts "No public ID found. Code #{resp.code}:#{resp.body}"
         return {}
      end
      if json['results'].length > 1
         puts "Multiple hits found for #{filename}"
         return {}
      end

      # pull some key info out of the search response. ID will be used for a metadata call
      hit = json['results'].first
      coll = hit['collectiontypenameid'].first.split("|")[1]
      coll_id = hit['collectiontypenameid'].first.split("|")[2]
      out =  {id: hit['artstorid'], collection_id: coll_id, collection: coll, date: hit["date"] }

      puts "Find matdata for #{filename}:#{out[:id]}"
      resp = RestClient.get("#{api_url}/v1/metadata?object_ids=#{out[:id]}&legacy=false", 
         {content_type: :json, authority: "library.artstor.org", cookies: cookies})
      if resp.code != 200 
         puts "No metadata found. Code #{resp.code}:#{resp.body}"
         return out
      end

      json = JSON.parse(resp.body)
      if json['total'] == 0 
         puts "No metadata found. Code #{resp.code}:#{resp.body}"
         return out
      end
      if json['total'] > 1
         puts "Multiple metadata hits found for #{out[:id]}"
         return out
      end
      hit = json["metadata"].first
      out[:ssid] = hit["SSID"]
      out[:width] = hit["width"]
      out[:height] = hit["height"]
      out[:title] = ""
      hit["metadata_json"].each do |md|
         if md["fieldName"] == "Creator" 
            out[:creator] = md["fieldValue"]
         end
         if md["fieldName"] == "Description" 
            out[:desc] = md["fieldValue"]
         end
         if md["fieldName"] == "Title" 
            if out[:title].length > 0 
               out[:title] << " "
            end 
            out[:title] << md["fieldValue"]
         end
      end

      return out
   end
end