class Api::ApTrustController < ApplicationController
   # Resubmit an item to APTRust
   def resubmit 
      render plain: "NO", status: :not_found
   end
end