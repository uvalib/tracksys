class Api::StyleController < ApplicationController
   def show
      is = IndexingScenario.find_by(id: params[:id])
      render :text=>"Could not find indexing scenario", status: :not_found and return if is.nil?

      if is.name.downcase.include? "default"
         style_xsl = File.read("#{Rails.root}/lib/xslt/defaultModsTransformation.xsl")
         render :xml=>style_xsl
      else
         style_xsl = File.read("#{Rails.root}/lib/xslt/holsingerTransformation.xsl")
         render :xml=>style_xsl
      end
   end
end
