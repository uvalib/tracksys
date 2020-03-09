class Api::AsController < ApplicationController
   # Generate a CSV of items recently added to AS. Columns needed:
   # PID, Title, Date added, AS URL, TS Admin URL
   #
   def report 
      num_days = params[:days] 
      if num_days.blank? 
         render plain: "Param days is required", status: :bad_request
         return
      end

      as_info = ExternalSystem.find(1)
      Rails.logger.info("Report of AS additions in the last #{num_days} days (#{num_days.to_i.days.ago})")
      out = "pid,title,date,archivesspace_url,tracksys_url\n"
      hits = ExternalMetadata.where("external_system_id=? and updated_at > ?", 1, num_days.to_i.days.ago).order(updated_at: :desc)
      hits.each do |m| 
         ts = "#{Settings.tracksys_url}/admin/external_metadata/#{m.id}"
         as = "#{as_info['public_url']}/#{m.external_uri}"
         out << "#{m.pid},#{m.title},#{m.updated_at.strftime('%F')},#{as},#{ts}\n"
      end

      send_data out, filename: "archivesspace-#{Date.today}-#{num_days}.csv"
   end
end