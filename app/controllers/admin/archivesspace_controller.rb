class Admin::ArchivesspaceController < ApplicationController
   # Convert an existing metadata record to external ArchivesSpace
   #
   def convert
      begin
         payload = { metadataID: params[:metadata_id], asURL: params[:as_url], userID: "#{current_user.id}" }
         RestClient.post "#{Settings.jobs_url}/archivesspace/convert" ,payload.to_json
         render plain: "Existing metadata converted to ArchivesSpace"
      rescue Exception=>e
         Rails.logger.error "ArchivesSpace conversion failed: #{e.to_s}"
         render plain: e.to_s, status:  :bad_request
      end
   end

   # validate the form of a URL. if it is symbolic, convert to numeric. Verify link returns good data.
   def validate
      begin
         resp = RestClient.get "#{Settings.jobs_url}/archivesspace/validate?url=#{params[:as_url]}"
         render plain: resp.body
      rescue => exception
         render plain: "Validate Failed: #{exception.to_s}", status: :internal_server_error
      end
   end

   def lookup
      Rails.logger.info "ArchivesSpace lookup: #{params[:uri]}"
      begin
         resp = RestClient.get "#{Settings.jobs_url}/archivesspace/lookup?uri=#{params[:uri]}"
         as_info = JSON.parse(resp.body)
         Rails.logger.info "AS response: #{as_info}"
         render json: as_info
      rescue => exception
         render plain: "Lookup Failed: #{exception.to_s}", status: :internal_server_error
      end
   end
end
