class Api::PidController < ApplicationController
   def show
      render :plain=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      # check each model that can have a PID to find a match. start
      # with most likely (metadata) and proceed down (masterfile, component)
      obj = Metadata.find_by(pid: params[:pid])
      if !obj.nil?
         policy = "private"
         policy = obj.availability_policy.name if !obj.availability_policy_id.nil?
         out = {id: obj.id, pid: obj.pid, type: obj.type.underscore, title: obj.title, availability_policy: policy}
         if !obj.ocr_hint_id.nil?
            out[:ocr_hint] = obj.ocr_hint.name
         end
         if !obj.ocr_language_hint.blank?
            if obj.ocr_language_hint.length == 3
               out[:ocr_language_hint] = obj.ocr_language_hint
            end
         end
         render json: out, status: :ok
         return
      end

      obj = MasterFile.find_by(pid: params[:pid])
      if !obj.nil?
         out = {id: obj.id, pid: obj.pid, type: "master_file", title: obj.title, filename: obj.filename }
         if !obj.original_mf_id.nil?
            orig = MasterFile.find(obj.original_mf_id)
            out[:cloned_from] = {id: orig.id, pid: orig.pid, filename: orig.filename }
         end
         render json: out, status: :ok
         return
      end

      type = "component"
      url_frag = "components"
      object = Component.find_by(pid: params[:pid])
      if object.nil?
         render :plain=>"Could not find PID", status: :not_found
      else
         render :json=>{id: object.id, type: type, title: object.name}, status: :ok
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
