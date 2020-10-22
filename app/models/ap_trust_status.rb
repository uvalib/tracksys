class ApTrustStatus < ApplicationRecord
   belongs_to :metadata

   def refresh
      resp = ApTrust.status(self.etag)
      if !resp.nil?
         self.update(status: resp[:status], note: resp[:note])
         logger.info("Refreshing APTrust Status: #{resp[:status]}, stage: #{resp[:stage]}")

         if resp[:status] == "Failed" || resp[:status] == "Success"
            self.update(finished_at: resp[:finished_on], object_id: resp[:object_id])
         end
      end
   end
end
