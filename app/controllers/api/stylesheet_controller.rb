class Api::StylesheetController < ApplicationController
   def show
      id = params[:id]
      if id.downcase == "default"
         style_xsl = File.read("#{Rails.root}/lib/xslt/defaultModsTransformation.xsl")
         render :xml=>style_xsl
      elsif id.downcase == "holsinger"
         style_xsl = File.read("#{Rails.root}/lib/xslt/holsingerTransformation.xsl")
         render :xml=>style_xsl
      elsif id.downcase == "user"
         uuid = params[:uuid]
         tgt_file = File.join(Rails.root, "tmp", "xsl", "#{uuid}.xsl")
         if File.exist? tgt_file
            style_xsl = File.read("#{Rails.root}/tmp/xsl/#{uuid}.xsl")
            render :xml=>style_xsl
         else
            render plain: "stylesheet not found", status: :not_found
         end
      elsif id.downcase == "marctomods"
         style_xsl = File.read("#{Rails.root}/lib/xslt/MARC21slim2MODS3-6_rev.xsl")
         render :xml=>style_xsl
      else
         render :plain=>"Invalid stylesheet requested", status: :not_found
      end
   end
end
