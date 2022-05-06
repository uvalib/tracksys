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
         resp = RestClient.get "#{Settings.jobs_url}/archivesspace/lookup?uri=#{self.external_uri}&pid=#{self.pid}"
         as_info = JSON.parse(resp.body)
      rescue Exception => e
         logger.error "Unable to get AS info for #{self.id}: #{e.to_s}"
         as_info = {}
      ensure
         return as_info
      end
   end
end
