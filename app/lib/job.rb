module Job
   class Response
      def initialize(status, message, job_id)
         @status = status
         @message = message
         @job_id = job_id
      end
      def Response.error(message)
         return Response.new(:error, message, nil)
      end
      def Response.success()
         return Response.new(:done, nil, nil)
      end
      def Response.running(job_id)
         return Response.new(:running, nil, job_id)
      end
      def message
         @message
      end
      def status
         @status
      end
      def job_id
         @job_id
      end
      def success?
         return status == :done
      end
   end

   # submit a job to the backened processing service. Retuns
   #
   def self.submit(url, params)
      begin
         json_data = nil
         if !params.nil?
            json_data = params.to_json
         end
         resp = RestClient.post "#{Settings.jobs_url}#{url}", json_data
         if resp.body == "done"
            return Response.success
         else
            return Response.running(resp.body.to_i)
         end
      rescue => exception
         Rails.logger.error "ERROR: Job #{url} failed: #{exception}"
         return Response.error(exception)
      end
   end

   def self.attach_file( unit_id, attachment, desc )
      filename = attachment.original_filename
      # upload_file = attachment.tempfile.path
      begin
         RestClient.post "#{Settings.jobs_url}/units/#{unit_id}/attach", {:file => File.new(attachment.tempfile.path, 'rb'), :name => filename, :description => desc }
         return true, ""
      rescue => exception
         Rails.logger.error "ERROR: attach #{filename} failed: #{exception}"
         return false,  exception.response.body
      end
   end
end


