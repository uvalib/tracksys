class Api::OtherController < ApplicationController
   def published
      out = {items: []}
      XmlMetadata.where("date_dl_ingest is not null").distinct().find_each do |m|
         out[:items] << m.pid
      end
      render json: out
   end

   def show
      out = { pid: params[:id], pdfServiceRoot: Settings.pdf_url}
      found = false
      md = XmlMetadata.find_by(pid: params[:id])
      if md.blank?
         render plain: "Not Found", status: :not_found
         return
      end
      if md.date_dl_ingest.blank?
         render plain: "Not published", status: :bad_request
         return
      end

      out[:collection] = md.collection_facet if !md.collection_facet.blank?

      uses = []
      uses << "Educational Use Permitted" if md.use_right.educational_use
      uses << "Commercial Use Permitted" if md.use_right.commercial_use
      uses << "Modifications Permitted" if md.use_right.modifications

      manifestURL = ""
      resp = RestClient.get "#{Settings.iiif_manifest_url}/pid/#{md.pid}/exist"
      if resp.code.to_i == 200
         json = JSON.parse(resp.body)
         if json['cached'] == true
            manifestURL = json['url']
         end
      end
      if manifestURL == ""
         Rails.logger.error "IIIF Manifest cache not found for #{md.pid}"
         render plain: "Not Found", status: :not_found
         return
      end

      out[:rsURI] = md.use_right.uri
      out[:rsUses] = uses
      out[:backendIIIFManifestUrl] = manifestURL

      if md.has_exemplar?
         out[:thumbnailUrl] = md.exemplar_info[:url]
      end

      render json: out
   end
end