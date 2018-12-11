module ApTrust 
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
end