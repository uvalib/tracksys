class Api::QdcController < ApplicationController
   def generate
      begin
         PublishQDC.exec_now({metadata_id: params[:id]})
         meta = Metadata.find( params[:id] )
         render plain: meta.qdc_generated_at.strftime('%F %r'), status: :ok
      rescue Exception=>e
         logger.error("Generate QDC FAILED: #{e.class.name} - #{e.message}}")
         render plain: "#{e.class.name}: #{e.message}}", status: :error
      end
   end
end
