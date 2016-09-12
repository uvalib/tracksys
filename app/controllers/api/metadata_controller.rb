class Api::MetadataController < ApplicationController
   def show
      render :text=>"type is required", status: :bad_request and return if params[:type].blank?
      type = params[:type].strip.downcase
      render :text=>"#{type} is not supported", status: :bad_request and return if type != "desc_metadata"
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      #parse pid for item identity; format TS[B|M]:[id]
      pid_bits = params[:pid].split(":")
      id = pid_bits.last
      resource_type = pid_bits.first[2].upcase
      if resource_type == "B"
         object = Metadata.find(id)
      elsif resource_type == "M"
         object = MasterFile.find(id)
      else
         # see if it is an old-style PID
         object = Metadata.find_by(pid: params[:pid])
         if object.nil?
            object = MasterFile.find_by(pid: params[:pid])
         end
         render :text=>"PID is invalid", status: :bad_request and return if object.nil?
      end

      if type == "desc_metadata"
         if object.desc_metadata.blank?
            render :xml=> Hydra.desc(object)
         else
            render :xml=> object.desc_metadata
         end
      end
   end
end
