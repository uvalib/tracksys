module Jstor 

   # JSTOR Forum login and return cookies
   #
   def self.forum_login ( forum_url )
      puts "authenticating with JSTOR Forum..."
      form = {email: Settings.jstor_email, password: Settings.jstor_pass}
      resp = RestClient.post("#{jforum_url}/account", form)
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

   # Seacrh the ArtStor public API by filename
   #
   def self.find_public_id(public_url, filename, cookies)
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
      return json['results'].first['artstorid']
   end
end