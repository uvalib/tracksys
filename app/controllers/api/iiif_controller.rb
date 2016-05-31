class Api::IiifController < ApplicationController

   after_filter :set_cors_headers

   def set_cors_headers
      headers['Access-Control-Allow-Origin'] = '*'
      headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
      headers['Access-Control-Request-Method'] = '*'
      headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
   end

   # Get the Json IIIF metadata for the bibl
   #
   def show
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")

      pid = params[:pid].downcase
      if pid.match(/\Atsb:\d+\z/)
         id = pid.split(":").last.to_i
         @bibl = Bibl.find_by(id: id)
      else
         @bibl = Bibl.find_by(pid: params[:pid])
      end

      render :text=>"PID is invalid", status: :bad_request and return if @bibl.nil?

      render "/api/iiif/show.json"
   end
end
