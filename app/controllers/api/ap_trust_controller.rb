class Api::ApTrustController < ApplicationController
   # Resubmit an item to APTRust
   #
   def resubmit 
      md = Metadata.find(params[:id])
      if md.ap_trust_status.blank?
         render plain: "This item has not previously been submitted to APTrust", status: :bad_request
         return
      end

      if md.ap_trust_status.status != "Success" &&  md.ap_trust_status.status != "Failed"
         render plain: "This item has a pending APTrust submission", status: :bad_request
         return
      end

      PublishToApTrust.exec({metadata: md})

      render plain: "submitted"
   end
end