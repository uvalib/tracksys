class Api::MetadataController < ApplicationController
   def show
      render :text=>"type is required", status: :bad_request and return if params[:type].blank?
      type = params[:type].strip.downcase
      render :text=>"#{type} is not supported", status: :bad_request and return if type != "desc_metadata"
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      object = Metadata.find_by(pid: params[:pid])
      if object.nil?
         object = MasterFile.find_by(pid: params[:pid])
      end
      render :text=>"PID is invalid", status: :bad_request and return if object.nil?

      if type == "desc_metadata"
         render :xml=> Hydra.desc(object)
      end
   end
end
