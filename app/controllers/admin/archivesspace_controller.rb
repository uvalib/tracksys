class Admin::ArchivesspaceController < ApplicationController
   def lookup
      render json: ArchivesSpace.lookup(params[:uri])
   end

   def create
      unit = Unit.find(params[:id])
      publish = params[:publish] == "true"
      begin
         LinkToAs.exec_now({unit: unit, as_url: params[:as_url],
            publish: publish, staff_member: current_user })
         render plain: "ArchivesSpace metadata link created"
      rescue Exception=>e
         Rails.logger.error "ArchivesSpace link failed: #{e.to_s}"
         render plain: e.to_s, status:  :error
      end
   end
end
