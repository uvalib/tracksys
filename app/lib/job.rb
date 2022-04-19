module Job
   def self.submit(url, params)
      begin
         json_data = nil
         if !params.nil?
            json_data = params.to_json
         end
         RestClient.post "#{Settings.jobs_url}#{url}", json_data
      rescue => exception
         Rails.logger.error "ERROR: Job #{url} failed: #{exception.response.body}"
         return false
      end
      return true
   end
end


