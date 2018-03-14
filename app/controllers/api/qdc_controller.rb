class Api::QdcController < ApplicationController
   def generate
      PublishQDC.exec_now({metadata_id: params[:id]})
      meta = Metadata.find( params[:id] )
      render text: meta.qdc_generated_at.strftime('%F %r'), status: :ok
   end
end
