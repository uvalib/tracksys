class Api::CallbacksController < ApplicationController

   # callback from OCR service. Accepts results, and mark job as complete
   #
   def ocr
      job_id = params[:jid]
      job = JobStatus.find_by(id: job_id)
      render plain: "Job ID not found", status: :not_found and return if job.nil?

      job_logger = job.create_logger()
      resp = JSON.parse(params[:json])
      job_logger.info "OCR processing started at #{resp['started']}"
      if resp["status"] == "success"
         job_logger.info "OCR successfully completed at #{resp['finished']}"
         job.finished
      else 
         job_logger.fatal "OCR FAILED at #{resp['finished']}"
         job_logger.fatal "Failure details #{resp['message']}"
         job.failed( resp['message'])
      end
      render plain: "ok"
   end

   # Callback from OCR service that was triggered from finalization.
   # Instead of marking the job success/fail flag the OCR completion 
   # in redis. The job is watching for this signal and will unblock 
   # based on the setting in redis
   #
   def synchronous_ocr
      job_id = params[:jid]
      redis = Redis.new(host: Settings.redis_host, password: Settings.redis_pass)
      redis_key = "#{Settings.redis_prefix}:ocr_#{job_id}"
      ocr_status = redis.get(redis_key)
      if ocr_status.nil? 
         logger.error("No OCR job status for job #{job_id} found!")
         render plain: "Job ID not found", status: :not_found
      else
         resp = JSON.parse(params[:json])
         if resp["status"] == "success"
            redis.set(redis_key, "success")    
         else 
            redis.set(redis_key, "OCR FAILED: #{resp['message']}")
         end
         render plain: "ok"
      end
   end
end