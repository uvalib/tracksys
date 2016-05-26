class Api::MetadataController < ApplicationController
   def index
      render :text=>"pid is required", status: :bad_request and return if params[:pid].blank?
      render :text=>"type is required", status: :bad_request and return if params[:type].blank?
      type = params[:type].strip.downcase
      render :text=>"Only desc_metadata is supported", status: :bad_request and return if type != "desc_metadata"

      #parse pid for item identity; format TS[B|U|M]:[id]
      pid_bits = params[:pid].split(":")
      id = pid_bits.last
      resource_type = pid_bits.first[2].upcase
      if resource_type == "B"
         object = Bibl.find(id)
      elsif resource_type == "M"
         object = MasterFile.find(id)
      else
         object = Bibl.find_by(pid: params[:pid])
         if object.nil?
            object = MasterFile.find_by(pid: params[:pid])
         end
         render :text=>"PID is invalid", status: :bad_request and return if object.nil?
      end

      if object.desc_metadata.blank?
         render :xml=> Hydra.desc(object)
      else
         render :xml=> object.desc_metadata
      end
   end
end
