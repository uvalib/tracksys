class Api::SirsiController < ApplicationController
   def show
      resp = { sirsiId: params[:id], pdfServiceRoot: Settings.pdf_url, items: [] }
      found = false
      Metadata.where("catalog_key=?", params[:id]).order(call_number: :asc).each do |sm|
         next if sm.date_dl_ingest.nil? || !sm.discoverability
         resp[:collection] = sm.collection_facet if !sm.collection_facet.blank?
         found = true

         rights = sm.use_right.statement
         rights << "\nFind more information about permission to use the library's materials at http://search.lib.virginia.edu/terms.html."
         uses = []
         uses << "Educational Use Permitted" if sm.use_right.educational_use
         uses << "Commercial Use Permitted" if sm.use_right.commercial_use
         uses << "Modifications Permitted" if sm.use_right.modifications

         # Try to get the S3 URL from pidcache. If it fails, the old IIIF service
         # is still in place; use the original URL
         manifestURL = "#{Settings.iiif_manifest_url}/#{sm.pid}"
         resp = RestClient.get "#{Settings.iiif_manifest_url}/pidcache/#{sm.pid}"
         if resp.code.to_i == 200
            json = JSON.parse(resp.body)
            manifestURL = json['url']
         end

         item =  {
            pid: sm.pid, callNumber: sm.call_number, barcode: sm.barcode,
            rsURI: sm.use_right.uri,
            rsUses: uses,
            rightsWrapperUrl: "#{Settings.rights_wrapper_url}/?pid=#{sm.pid}&pagePid=",
            rightsWrapperText: "#{sm.get_citation}\n#{Settings.virgo_url}/#{sm.pid}\n\n#{rights}",
            backendIIIFManifestUrl: manifestURL
         }

         if sm.has_exemplar?
            item[:thumbnailUrl] = sm.exemplar_info[:url]
         end

         resp[:items] << item
      end

      if found
         render json: resp
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
