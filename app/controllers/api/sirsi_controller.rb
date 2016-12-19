class Api::SirsiController < ApplicationController
   def show
      resp = { sirsiId: params[:id], pdfServiceRoot: Settings.pdf_url, items: [] }
      Metadata.where("date_dl_ingest is not null and type=? and catalog_key=?", "SirsiMetadata", params[:id]).each do |sm|
         resp[:collection] = sm.collection_facet if !sm.collection_facet.blank?

         thumb_pid = ""
         if sm.exemplar.blank?
            thumb_pid = sm.master_files.first.pid if sm.master_files.count > 0
         else
            thumb_pid = MasterFile.find_by("filename = ?", sm.exemplar).pid
         end

         rights = ""
         if sm.use_right_id ==  3      # in copyright
            rights << "The UVA Library has determined that this work is in-copyright.\n"
            rights << "This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.\n"
            rights << "Copyright and other restrictions may apply to any further use of this image.\n"
         elsif sm.use_right_id == 2    # no known copyright
            rights << "The UVA Library is not aware of any copyright interest in this work.\n"
            rights << "This single copy was produced for purposes of private study, scholarship, or research. You are responsible for making a rights determination for your own uses.\n"
         else                          # default to not evaluated
            rights << "The UVA Library has not evaluated the copyright status of this work.\n"
            rights << "This single copy was produced for purposes of private study, scholarship, or research, pursuant to the library's rights under the Copyright Act.\n"
            rights << "Copyright and other restrictions may apply to any further use of this image.\n"
         end
         rights << "See the full Virgo Terms of Use at http://search.lib.virginia.edu/terms.html for more information."

         item =  {
            pid: sm.pid, callNumber: sm.call_number,
            rightsWrapperUrl: "#{Settings.rights_wrapper_url}/?pid=#{sm.pid}&pagePid=",
            rightsWrapperText: "#{sm.get_citation}\n#{Settings.virgo_url}/#{sm.pid}\n\n#{rights}",
            backendIIIFManifestUrl: "#{Settings.iiif_manifest_url}/#{sm.pid}"
         }
         item[:thumbnailUrl] = "#{Settings.iiif_url}/#{thumb_pid}/full/!125,125/0/default.jpg" if !thumb_pid.blank?

         resp[:items] << item
      end
      render json: resp
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
