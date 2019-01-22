class Admin::ArchivesspaceController < ApplicationController
   def lookup
      render json: ArchivesSpace.lookup(params[:uri])
   end

   # Convert an existing metadata record to external ArchivesSpace
   #
   def convert
      begin
         ConvertToAs.exec_now({metadata_id: params[:metadata_id], as_url: params[:as_url], staff_member: current_user })
         render plain: "Existing metadata converted to ArchivesSpace"
      rescue Exception=>e
         Rails.logger.error "ArchivesSpace conversion failed: #{e.to_s}"
         render plain: e.to_s, status:  :error
      end
   end
end
