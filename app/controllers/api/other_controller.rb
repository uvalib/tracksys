class Api::OtherController < ApplicationController
   def published
      out = {items: []}
      XmlMetadata.where("date_dl_ingest is not null").find_each do |m|
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

      rights = md.use_right.statement
      rights << "\nFind more information about permission to use the library's materials at http://search.lib.virginia.edu/terms.html."
      uses = []
      uses << "Educational Use Permitted" if md.use_right.educational_use
      uses << "Commercial Use Permitted" if md.use_right.commercial_use
      uses << "Modifications Permitted" if md.use_right.modifications

      # Try to get the S3 URL from pidcache. If it fails, the old IIIF service
      # is still in place; use the original URL
      manifestURL = "#{Settings.iiif_manifest_url}/#{md.pid}"
      resp = RestClient.get "#{Settings.iiif_manifest_url}/pidcache/#{md.pid}"
      if resp.code.to_i == 200
         json = JSON.parse(resp.body)
         manifestURL = json['url']
      end

      out[:rsURI] = md.use_right.uri,
      out[:rsUses] = uses,
      out[:backendIIIFManifestUrl] = manifestURL

      if md.has_exemplar?
         out[:thumbnailUrl] = md.exemplar_info[:url]
      end

      render json: out
   end
end