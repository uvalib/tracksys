class Api::PidController < ApplicationController
   def show
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      # check each model that can have a PID to find a match. start
      # with most likely (metadata) and proceed down (masterfile, component)
      object = Metadata.find_by(pid: params[:pid])
      if object.nil?
         type = "master_file"
         object = MasterFile.find_by(pid: params[:pid])
      else
         type = object.type.underscore
      end
      if object.nil?
         type = "component"
         object = Component.find_by(pid: params[:pid])
      end
      if object.nil?
         render :text=>"Could not find PID", status: :not_found
      else
         render :json=>{id: object.id, type: type}, status: :ok
      end
   end
end
