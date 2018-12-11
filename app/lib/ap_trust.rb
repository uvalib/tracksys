module ApTrust 
   # Submit the specified tar file to APTrust. An etag is returned that can be used to 
   # track submission status
   def self.submit ( tar_path )
      Rails.logger.info( "Submit bag #{tar_path} to APTrust #{Settings.aws_bucket}" )
      puts "connect to S3..."
      client = Aws::S3::Client.new

      puts "put object..."
      etag = ""
      File.open(tar_path, 'rb') do |file|
         resp = client.put_object(bucket: Settings.aws_bucket, key: File.basename(tar_path), body: file)
         etag = resp.to_h[:etag]
      end
      return etag
   end

   # Use an etag to check the status of an APTrust ingest
   def self.status ( etag )
      headers = {content_type: :json, accept: :json, "X-Pharos-API-User": Settings.aptrust_user, "X-Pharos-API-Key": Settings.aptrust_key}
      resp = RestClient.get "#{Settings.aptrust_api_url}/items?etag=#{etag}", headers
      status = JSON.parse(resp.body)["results"][0]
      out = {status: status["status"], stage: status["stage"], note: status["note"], started_on: status["bag_date"], finished_on: status["date"]}
      return out
   end
end