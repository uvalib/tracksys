class Api::SirsiController < ApplicationController
   def published
      out = {items: []}
      SirsiMetadata.where("date_dl_ingest is not null").pluck(:catalog_key).uniq.each do |m|
         out[:items] << m
      end
      render json: out
   end

   def show
      out = { sirsiId: params[:id], pdfServiceRoot: Settings.pdf_url, items: [] }
      found = false
      SirsiMetadata.where("catalog_key=?", params[:id]).order(call_number: :asc).each do |sm|
         next if sm.date_dl_ingest.blank?
         next if !sm.units.where(include_in_dl: true).exists?

         out[:collection] = sm.collection_facet if !sm.collection_facet.blank?
         found = true

         uses = []
         uses << "Educational Use Permitted" if sm.use_right.educational_use
         uses << "Commercial Use Permitted" if sm.use_right.commercial_use
         uses << "Modifications Permitted" if sm.use_right.modifications

         manifestURL = ""
         resp = RestClient.get "#{Settings.iiif_manifest_url}/pid/#{sm.pid}/exist"
         if resp.code.to_i == 200
            json = JSON.parse(resp.body)
            if json['cached'] == true
               manifestURL = json['url']
            end
         end
         if manifestURL == ""
            Rails.logger.error "IIIF Manifest cache not found for #{sm.pid}"
            render plain: "Not Found", status: :not_found
            return
         end

         item =  {
            pid: sm.pid, callNumber: sm.call_number, barcode: sm.barcode,
            rsURI: sm.use_right.uri,
            rsUses: uses,
            backendIIIFManifestUrl: manifestURL
         }

         if sm.has_exemplar?
            item[:thumbnailUrl] = sm.exemplar_info[:url]
         end

         out[:items] << item
      end

      if found
         render json: out
      else
         render plain: "Not Found", status: :not_found
      end
   end
end

# Template for response:
# ======================
# { "sirsiId": "u54534",
#   "pdfServiceRoot": "http://pdfws-test.lib.virginia.edu:8088/",
#   "collection": "McGregor Grant Collection",
#   "items": [
#    { "pid": "tsb:18138",
#      "callNumber": "A 1667 .G743 T72",
#      "thumbnailUrl": "http://iiif-test.lib.virginia.edu/iiif/tsm:1250691/full/!125,125/0/default.jpg",
#      "rightsWrapperUrl": "http://rightswrapper2-test.lib.virginia.edu:8090/rights-wrapper/?pid=tsb:18138&pagePid=",
#      "rightsWrapperText": "Articulen van vrede ende verbondt, tusschen den doorluchtighsten, grootmachtighsten prins ende heer,
#                            Heere Karel, de tweede van dien naem, Koningh van Groot Britannien, ter eenre; ende de hoogh mogende heeren
#                            Staten Generael der Vereenighde Nederlandtsche Provintien, ter andere zijde geslooten,
#                            Special Collections, University of Virginia Library, Charlottesville, Va.\n
#                            http://docker1.lib.virginia.edu:8061/catalog/u54534\n\n
#                            The UVA Library has not evaluated the copyright status of this work.\nThis single copy was produced for purposes of
#                            private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.\n
#                            Copyright and other restrictions may apply to any further use of this image.\n\n
#                            See the full Virgo Terms of Use at http://search.lib.virginia.edu/terms.html for more information.",
#      "backendIIIFManifestUrl": "http://tracksysdev.lib.virginia.edu:8080/tsb:18138"
#    } ]
# }
