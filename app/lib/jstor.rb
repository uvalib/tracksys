module Jstor 

   # JSTOR Forum login and return cookies
   #
   def self.forum_login ( forum_url )
      puts "authenticating with JSTOR Forum..."
      form = {email: Settings.jstor_email, password: Settings.jstor_pass}
      resp = RestClient.post("#{forum_url}/account", form)
      if resp.code != 200 
         raise "JSTOR authentication failed: #{resp.body}"
      end
      puts "Successfully authenticated to JSTORForum"
      resp.cookie_jar.cookies
   end

   # Start an Artstor public sesssion and return cookies
   #
   def self.start_public_session ( public_url )
      puts "Starting Artstor public session..."
      resp = RestClient.get("#{public_url}/api/secure/userinfo")
      if resp.code != 200 
         raise "Public authentication failed: #{resp.body}"
      end
      puts "Successfully authenticated to puiblic ARTSTOR API"
      resp.cookie_jar.cookies
   end

   # Search the private forum API for ID by filename
   #
   def self.find_id(forum_url, filename, cookies)
      puts "Check for JSTOR ID[#{filename}]"
      p  = {type: "string", field: "filename", fieldName: "Filename", value: filename}.to_json
      p = p.gsub(/\"/, "%22").gsub(/{/,"%7B").gsub(/}/, "%7D")
      f = "filter=[#{p}]"
      q = "#{forum_url}/projects/64/assets?with_meta=false&start=0&limit=1&sort=id&dir=DESC&#{f}"
      resp = RestClient.get(q,{cookies: cookies})
      if resp.code != 200
         puts "ERROR: JSTOR requst for #{filename} FAILED - #{resp.code}:#{resp.body}"
         return ""
      end
      json = JSON.parse(resp.body)
      if json['total'] == 0 
         puts "No item found for #{filename}"
         return ""
      end
      if json['total'] > 1 
         puts "WARN: Too many matches (#{json['total']}) found for #{filename}"
         return ""
      end

      return json["assets"].first["id"]
   end

   # Search the ArtStor public API by filename
   #
   def self.find_public_info(public_url, filename, cookies)
      puts "Find public ID for #{filename}"
      params = {limit: 1, start: 0, content_types: ["art"], query: "#{filename}"}
      resp = RestClient.post("#{public_url}//api/search/v1.0/search", 
         params.to_json, {content_type: :json, authority: "library.artstor.org", cookies: cookies})
      if resp.code != 200 
         puts "No public ID found. Code #{resp.code}:#{resp.body}"
         return nil
      end
      json = JSON.parse(resp.body)
      if json['total'] == 0 || json['total'] > 1
         puts "No public ID found. Code #{resp.code}:#{resp.body}"
         return nil
      end
      hit = json['results'].first
      media = JSON.parse(hit['media'])
      out =  {id: hit['artstorid'], title: hit['name'], date: hit['date'], type: hit['type'] }
      if !media.nil?
         out[:width] = media["width"]
         out[:height] = media["height"]
      end
      return out
   end
end