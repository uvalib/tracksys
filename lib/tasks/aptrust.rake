namespace :aptrust do
   desc "Submit a bg containing a single item"
   task :submit_one  => :environment do
      pid = ENV['pid']
      id = ENV['id']
      storage = ENV['storage']
      abort("PID or ID is required") if pid.nil? && id.nil? 
      abort("Storage is required") if storage.nil?
      abort("Storage must be standard or glacier") if !["standard", "glacier"].include?(storage)

      metadata = nil
      if !id.nil?
         metadata = Metadata.find(id)
      else 
         metadata = Metadata.find_by(pid: pid)
      end
      abort("Invalid PID or ID") if metadata.nil?

      tier_id = 2 
      tier_id = 3 if storage == "standard"

      # Block the automatic check and submission that happes in a callback
      # we will do it below instead...
      if metadata.preservation_tier_id != tier_id
         Metadata.skip_callback( :save, :after, :aptrust_checks)
         metadata.update(preservation_tier_id: tier_id)
      end
      PublishToApTrust.exec_now({metadata: metadata})
   end 
end