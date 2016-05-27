class Api::IiifController < ApplicationController

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
