module ApTrust
   # Submit the specified tar file to APTrust. An etag is returned that can be used to
   # track submission status
   def self.submit ( tar_path )
      $stdout.sync = true
      puts "Submit bag #{tar_path} to APTrust #{Settings.aws_bucket}"
      client = Aws::S3::Client.new

      etag = ""
      part_number = 1
      multipart_resp = client.create_multipart_upload(bucket: Settings.aws_bucket, key: File.basename(tar_path))
      upload_id = multipart_resp[:upload_id]
      parts = []
      completed_resp = nil
      Rails.logger.info("Starting multipart S3 upload: #{upload_id}")

      begin
         File.open(tar_path, 'rb') do |file|
            until file.eof?
               chunk = file.read(1024*1024*1024)
               puts "Sending chunk #{part_number}"
               resp = client.upload_part(bucket: Settings.aws_bucket, key: File.basename(tar_path),
                                       body: chunk, upload_id: upload_id, part_number: part_number)
               parts << {etag: resp.to_h[:etag], part_number: part_number}
               part_number += 1
            end
         end

         completed_resp = client.complete_multipart_upload(
            bucket: Settings.aws_bucket, key: File.basename(tar_path),
            multipart_upload: {parts: parts}, upload_id: upload_id
         )
      rescue Aws::S3::Errors => e
         abort_resp = client.abort_multipart_upload(bucket: Settings.aws_bucket, key: File.basename(tar_path), upload_id: upload_id)
         puts "Aborting upload: #{abort_resp.to_h}"
         raise e
      end

      etag = completed_resp.to_h[:etag]
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