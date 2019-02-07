class Api::CallbacksController < ApplicationController

   # callback from OCR service. Accepts results
   #
   def ocr
      job_id = params[:jid]
      job = JobStatus.find_by(id: job_id)
      render plain: "Job ID not found", status: :not_found and return if job.nil?

      job_logger = job.create_logger()
      job_logger.info "OCR started at #{params[:started]}"
      if params[:status] == "success"
         job_logger.info "OCR successfully completed at #{params[:finished]}"
         job.finished
      else 
         job_logger.fatal "OCR FAILED at #{params[:finished]}"
         job_logger.fatal "Failure details #{params[:message]}"
         job.failed( params[:message])
      end
   end
end