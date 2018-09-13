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
