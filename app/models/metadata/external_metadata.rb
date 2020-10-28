class ExternalMetadata < Metadata
   #------------------------------------------------------------------
   # Prevent setting data valid for other classes in the STI model
   validates :catalog_key, presence: false
   validates :barcode, presence: false
   validates :call_number, presence: false
   validates :desc_metadata, presence: false
   validates :external_system, presence: true
   validates :external_uri, presence: true

   before_save do
      # external metadata can not be published from tracksys
      self.discoverability = false
      self.availability_policy = nil
   end

   def url_fragment
      return "external_metadata"
   end

   def collection_name
      m = get_external_metadata
      return m[:id] || m[:pid]
   end

   def get_external_metadata
      case self.external_system.name
      when "ArchivesSpace"
         get_as_metadata
      when "Apollo"
         get_apollo_metadata
      when "JSTOR Forum"
         get_jstor_metadata
      end
   end

   def get_jstor_metadata
      js = self.external_system
      js_key = self.master_files.first.filename.split(".").first
      cookies = Jstor.start_session(js.api_url)
      pub_info = Jstor.public_info(js.api_url, js_key, cookies)
      js_info = {}
      js_info[:url] = "#{js.public_url}#{self.external_uri}"
      js_info[:collection_title] = pub_info[:collection]
      js_info[:collection_url] = "#{js.public_url}/#/collection/#{pub_info[:collection_id]}"
      js_info[:title] = pub_info[:title]
      js_info[:desc] = pub_info[:desc]
      js_info[:creator] = pub_info[:creator]
      js_info[:date] = pub_info[:date]
      js_info[:width] = pub_info[:width]
      js_info[:height] = pub_info[:height]
      js_info[:id] = pub_info[:id]
      js_info[:ssid] = pub_info[:ssid]
      return js_info
   end

   def get_apollo_metadata
      begin
         apollo = self.external_system
         resp = RestClient.get "#{apollo.public_url}#{self.external_uri}"
         json = JSON.parse(resp.body)
         coll_data = json['collection']['children']
         item_data = json['item']['children']
         apollo_info = {pid: json['collection']['pid'] }
         apollo_info[:collection] = coll_data.find{ |attr| attr['type']['name']=="title" }['value']
         apollo_info[:barcode] = coll_data.find{ |attr| attr['type']['name']=="barcode" }['value']
         apollo_info[:catalog_key] = coll_data.find{ |attr| attr['type']['name']=="catalogKey" }['value']
         right = coll_data.find{ |attr| attr['type']['name']=="useRights" }
         apollo_info[:rights] = right['value']
         apollo_info[:rights_uri] = right['valueURI']
         apollo_info[:item_pid] = json['item']['pid']
         apollo_info[:item_type] = json['item']['type']['name']
         apollo_info[:item_title] = item_data.find{ |attr| attr['type']['name']=="title" }['value']
      rescue Exception => e
         logger.error "Unable to get Apollo info for #{self.id}: #{e.to_s}"
         apollo_error = e.to_s
         apollo_info = {}
      ensure
         return apollo_info
      end
   end

   def get_as_metadata
      begin
         # First, authenticate with the API. Necessary to call other methods
         auth = ArchivesSpace.get_auth_session()
         as = self.external_system
         url = "#{as.public_url}#{self.external_uri}"
         tgt_obj = ArchivesSpace.get_details(auth, url)

         # build a data struct to represent the AS data
         title = tgt_obj['title']
         title = tgt_obj['display_string'] if title.blank?
         as_info = {
            title: title, created_by: tgt_obj['created_by'],
            create_time: tgt_obj['create_time'], level: tgt_obj['level'],
            url: url
         }
         dates = tgt_obj['dates'].first
         if !dates.nil?
            as_info[:dates] = dates['expression']
         end

         dobj = ArchivesSpace.get_digital_object(auth, tgt_obj, self.pid )
         if !dobj.nil?
            as_info[:published_at] = dobj[:created]
         end

         # pull repo ID from external URL and use it to lookup repo name:
         # /repositories/REPO_ID/resources/RES_ID
         repo_id = self.external_uri.split("/")[2]
         repo_detail = ArchivesSpace.get_repository(auth, repo_id)
         as_info[:repo] = repo_detail['name']


         if !tgt_obj['ancestors'].nil?
            anc = tgt_obj['ancestors'].last
            url = "#{as.api_url}#{anc['ref']}"
            coll = RestClient.get url, ArchivesSpace.auth_header(auth)
            coll_json = JSON.parse(coll.body)

            as_info[:collection_title] = coll_json['finding_aid_title'].split("<num")[0]
            as_info[:id] = coll_json['id_0']
            as_info[:language] = coll_json['language']

         else
            as_info[:collection_title] = tgt_obj['finding_aid_title'].split("<num")[0]
            as_info[:id] = tgt_obj['id_0']
            as_info[:language] = tgt_obj['language']
         end
      rescue Exception => e
         logger.error "Unable to get AS info for #{self.id}: #{e.to_s}"
         as_info = {}
      ensure
         return as_info
      end
   end
end
