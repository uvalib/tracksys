namespace :aptrust do
   desc "Submit a bg containing a single item"
   task :submit_one  => :environment do
      # Metadata ID or PID is required. Use it to get the metadata record
      pid = ENV['pid']
      id = ENV['id']   
      abort("PID or ID is required") if pid.nil? && id.nil? 
      metadata = nil
      if !id.nil?
         metadata = Metadata.find_by(id: id)
         abort("Invalid ID") if metadata.nil?
      else 
         metadata = Metadata.find_by(pid: pid)
         abort("Invalid PID") if metadata.nil?
      end
      puts "Send Metadata #{metadata.pid}: #{metadata.title} to APTrust"

      # Storage is optional and can be used to update preservation tier of metadata before submission
      storage = ENV['storage']
      if storage.nil?
         # No storage provided. Make sure the current tier setting is appropriate for APTrust
         if metadata.preservation_tier_id.blank? || metadata.preservation_tier_id == 1
            abort "Preservation Tier ID [#{metadata.preservation_tier_id}] not suitable for submission to APTrust"
         end
      else
         abort("Storage must be standard or glacier") if !["standard", "glacier"].include?(storage)

         tier_id = 2 
         tier_id = 3 if storage == "standard"

         # Block the automatic check and submission that happens in a callback
         # it will be done manually below instead
         if metadata.preservation_tier_id != tier_id
            puts "Update storage to tier #{tier_id}, #{storage} storage"
            Metadata.skip_callback( :save, :after, :aptrust_checks)
            metadata.update(preservation_tier_id: tier_id)
         else 
            puts "No updates necessary - storage already set to #{storage}"
         end
      end


      etag = PublishToApTrust.do_submission(metadata)
      puts "Bag submitted. Check status with etag: #{etag}"
   end 

   desc "Submit bags for a collection"
   task :submit_collection  => :environment do
      id = ENV['id']  
      coll_md = Metadata.find(id)
      puts "Sending children of collection #{coll_md.id}:#{coll_md.title} to APTrust"
      cnt = 0
      coll_md.children. each do |md|
         next if md.preservation_tier_id.blank? || md.preservation_tier_id == 1
         if md.ap_trust_status != nil
            puts "   Skipping MD #{md.id} as it already has APTrust status"
         end
         puts "   Submit child metadata #{md.id}"
         etag = PublishToApTrust.do_submission(md)
         puts "   Bag submitted. Check status with etag: #{etag}"
         cnt +=1
      end
      puts "DONE. #{cnt} bas submitted to APTrust"
   end

   desc "Update submitted APTrust status" 
   task :update_status => :environment do
      puts "Update status of all Submitted APTrust items.."
      cnt = 0
      pend = 0
      ApTrustStatus.where(status: "Submitted").each do |apt| 
         resp =  ApTrust::status(apt.etag)
         if !resp.nil?
            apt.update(status: resp[:status], note: resp[:note])  
            if resp[:status] == "Failed" || resp[:status] == "Success" 
               apt.update(finished_at: resp[:finished_on], object_id: resp[:object_id])
               cnt += 1
            else 
               pend += 1
            end
         end
      end
      puts "DONE. #{cnt} items completed, #{pend} items still processing"
   end

end