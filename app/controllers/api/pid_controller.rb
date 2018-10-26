class Api::PidController < ApplicationController
   def show
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      # check each model that can have a PID to find a match. start
      # with most likely (metadata) and proceed down (masterfile, component)
      object = Metadata.find_by(pid: params[:pid])
      if object.nil?
         type = "master_file"
         url_frag = "master_files"
         object = MasterFile.find_by(pid: params[:pid])
      else
         url_frag = type = object.type.underscore
      end
      if object.nil?
         type = "component"
         url_frag = "components"
         object = Component.find_by(pid: params[:pid])
      end
      if object.nil?
         render :plain=>"Could not find PID", status: :not_found
      else
         render :json=>{id: object.id, type: type, url: "#{Settings.tracksys_url}/admin/#{url_frag}/#{object.id}"}, status: :ok
      end
   end

   def rights
      safe_pid = ActiveRecord::Base.connection.quote(params[:pid])
      if Metadata.where("pid=?", params[:pid]).count > 0
         qs = "select a.name from metadata b inner join availability_policies a on a.id=b.availability_policy_id where b.pid=#{safe_pid}"
      elsif MasterFile.where("pid=?", params[:pid]).count > 0
         qs = "select a.name from master_files m inner join metadata b on b.id = m.metadata_id "
         qs << " inner join availability_policies a on a.id = b.availability_policy_id"
         qs << " where m.pid=#{safe_pid}"
      else
         render :plain=>"Could not find PID", status: :not_found
         return
      end

      out = Metadata.connection.execute(qs).first
      if out.blank?
         render :plain=>"private"
      else
         render :plain=> out[0].downcase.split(" ")[0]
      end
   end

   def identify
      obj = Metadata.find_by(pid: params[:pid])
      if !obj.nil?
         if obj.type == "SirsiMetadata"
            render plain: "sirsi_metadata" and return
         end
         if obj.type == "XmlMetadata"
            render plain: "xml_metadata" and return
         end
         if obj.type == "ExternalMetadata"
            if obj.external_system.name == "ArchivesSpace"
               render plain: "archivesspace_metadata" and return
            end
            if obj.external_system.name == "Apollo"
               render plain: "apollo_metadata" and return
            end
         end
         render plain: "unsupported metadata type", status: :bad_request
      end

      obj = Component.find_by(pid: params[:pid])
      if !obj.nil?
         render plain: "component" and return
      end

      obj = MasterFile.find_by(pid: params[:pid])
      if !obj.nil?
         render plain: "masterfile" and return
      end

      render plain: "invalid", status: :bad_request
   end
end
