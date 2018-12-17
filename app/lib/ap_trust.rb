module ApTrust 
   # Submit the specified tar file to APTrust. An etag is returned that can be used to 
   # track submission status
   def self.submit ( tar_path )
      Rails.logger.info( "Submit bag #{tar_path} to APTrust #{Settings.aws_bucket}" )
      client = Aws::S3::Client.new

      etag = ""
      File.open(tar_path, 'rb') do |file|
         resp = client.put_object(bucket: Settings.aws_bucket, key: File.basename(tar_path), body: file)
         etag = resp.to_h[:etag]
      end
      return etag.gsub(/\"/, "")
   end

   # Use an etag to check the status of an APTrust ingest
   def self.status ( etag )
      headers = {content_type: :json, accept: :json, "X-Pharos-API-User": Settings.aptrust_user, "X-Pharos-API-Key": Settings.aptrust_key}
      resp = RestClient.get "#{Settings.aptrust_api_url}/items?etag=#{etag}", headers
      if resp.code == 200
         results = JSON.parse(resp.body)["results"]
         if results.count > 0
            status = results.first
            out = {status: status["status"], stage: status["stage"], note: status["note"], 
               started_on: status["bag_date"], finished_on: status["date"], object_id: status["object_identifier"]}
            return out
         end
      end
      return nil
   end
end