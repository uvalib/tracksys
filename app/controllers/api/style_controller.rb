class Api::StyleController < ApplicationController
   def show
      render :text=>"PID is invalid", status: :bad_request and return if !params[:pid].include?(":")
      pid = params[:pid]
      if pid.downcase.include? "default"
         style_xsl = File.read("#{Rails.root}/lib/xslt/defaultModsTransformation.xsl")
         render :xml=>style_xsl
      elsif pid.downcase.include? "holsinger"
         style_xsl = File.read("#{Rails.root}/lib/xslt/holsingerTransformation.xsl")
         render :xml=>style_xsl
      else
         render :text=>"Could not find PID", status: :not_found
      end
   end
end
