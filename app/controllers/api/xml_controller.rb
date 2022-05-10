class Api::XmlController < ApplicationController
   def validate
      errors = XmlMetadata.validate params[:xml]
      if errors.length > 0
         render plain: errors.join("\n"), status: :bad_request
      else
         render plain: "valid", status: :ok
      end
   end

   def generate
      xml = render_to_string :template => "template/mods.xml",
         :locals => {:title => params[:title], :creator => params[:creator]}
      render xml: xml, status: :ok
   end
end
