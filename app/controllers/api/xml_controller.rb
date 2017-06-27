class Api::XmlController < ApplicationController
   def validate
      errors = XmlMetadata.validate params[:xml]
      if errors.length > 0
         render plain: errors.join("\n"), status: :error
      else
         render plain: "valid", status: :ok
      end
   end

   def generate
      xml = render_to_string :template => "template/mods.xml",
         :locals => {:title => params[:title], :creator => params[:creator],
            :genre => params[:genre], :resource_type => params[:type] }
      render xml: xml, status: :ok
   end
end
