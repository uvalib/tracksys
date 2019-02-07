module OCR
   # Perform OCR on all masterfile in a unit 
   #
   def self.unit(unit_id)
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
      ocr_log.info "Sending OCR request to #{url}..."
      resp = RestClient.get url
      if resp.code == 200 
         ocr_log.info "...request successfully submitted. Awaiting results."
      else 
         ocr_log.fatal "...submission failed. Code: #{resp.code}, Message: #{resp.body}"
         status.failed( resp.bod )
      end
   end
end