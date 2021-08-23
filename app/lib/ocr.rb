module OCR
   # Send out request to perform OCR on a unit, but don't return until
   # results are in. This is used when units are flagged for OCR during
   # finalization. Need to sit in this method until OCR is done because the OCR text
   # may be included with the patron zip. The job is the finalization job that wants OCR.
   #
   def self.synchronous(unit, job )
      md = unit.metadata
      lang = md.ocr_language_hint
      cb = "#{Settings.tracksys_url}/api/callbacks/#{job.status.id}/synchronous_ocr"
      url = "#{Settings.ocr_url}/#{md.pid}?lang=#{lang}&unit=#{unit.id}&force=true&callback=#{CGI.escape(cb)}"
      job.logger.info "Sending OCR request to #{url}"
      resp = RestClient.get url
      if resp.code == 200
         job.logger.info "Request successfully submitted. Awaiting results."
         redis = Redis.new(host: Settings.redis_host, port: Settings.redis_port, db: Settings.redis_db)
         redis_key = "#{Settings.redis_prefix}:ocr_#{job.status.id}"
         redis.set(redis_key, "waiting")
         while true do
            # await change in redis_key and break out of waiting
            sleep(60)
            val = redis.get(redis_key)
            if val != "waiting"
               if val == "success"
                  job.logger.info "OCR completed successfully"
               else
                  job.log_failure val
               end
               redis.del(redis_key)
               break
            end
         end
      else
         # request failed; log this as a warning and return to finalization
         job.log_failure("Submission failed. Code: #{resp.code}, Message: #{resp.body}")
      end
   end

   # Perform OCR on all masterfile in a unit
   #
   def self.unit(unit)
      status = JobStatus.create(name: "OCR", originator_type: "Unit", originator_id: unit.id)
      ocr_log = status.create_logger()
      ocr_log.info "Schedule OCR of Unit #{unit.id}"

      # call GET on OCR API specifiying the PID of the unit metadata record and unit id
      md = unit.metadata
      lang = md.ocr_language_hint
      cb = "#{Settings.tracksys_url}/api/callbacks/#{status.id}/ocr"
      url = "#{Settings.ocr_url}/#{md.pid}?lang=#{lang}&unit=#{unit.id}&force=true&callback=#{CGI.escape(cb)}"
      ocr_log.info "Sending OCR request to #{url}..."
      resp = RestClient.get url
      if resp.code == 200
         status.started
         ocr_log.info "...request successfully submitted. Awaiting results."
      else
         ocr_log.fatal "...submission failed. Code: #{resp.code}, Message: #{resp.body}"
         status.failed( resp.bod )
      end
   end

   # Perform OCR on a single master file
   #
   def self.master_file(mf)
      # create a job to track status
      status = JobStatus.create(name: "OCR", originator_type: "MasterFile", originator_id: mf.id)

      # create a log for the job and add a line for submission
      ocr_log = status.create_logger()
      ocr_log.info "Schedule OCR of MasterFile #{mf.id}"

      # call GET on OCR API with force=true
      lang = mf.metadata.ocr_language_hint
      cb = "#{Settings.tracksys_url}/api/callbacks/#{status.id}/ocr"
      url = "#{Settings.ocr_url}/#{mf.pid}?force=true&lang=#{lang}&callback=#{CGI.escape(cb)}"
      ocr_log.info "Sending OCR request to #{url}"
      resp = RestClient.get url
      if resp.code == 200
         status.started
         ocr_log.info "Request successfully submitted. Awaiting results."
      else
         ocr_log.fatal "Submission failed. Code: #{resp.code}, Message: #{resp.body}"
         status.failed( resp.bod )
      end
   end

   # Get a list of OCR languages
   #
   def self.languages
      lf = File.join(Rails.root, "data", "tesseract-langs.txt")
      return File.read(lf).split("\n").sort
   end
end
