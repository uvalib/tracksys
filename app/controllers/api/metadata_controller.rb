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
      elsif resource_type == "U"
         object = Unit.find(id)
      elsif resource_type == "M"
         object = MasterFile.find(id)
      else
         render :text=>"PID is invalid", status: :bad_request and return
      end

      render :xml=> Hydra.desc(object)
   end
end
