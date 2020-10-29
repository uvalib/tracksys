namespace :aptrust do
   desc "Submit a bg containing a single item"

   def submit_metadata metadata_id
      metadata = Metadata.find(metadata_id)
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
            puts "Updating metadata_id: #{metadata_id} tier #{tier_id}, #{storage} storage."
            metadata.update(preservation_tier_id: tier_id)
         else
            puts "No updates necessary for metadata_id: #{metadata_id} - storage already set to #{storage}"
         end
      end

      etag = PublishToApTrust.do_submission(metadata)
      puts "Bag submitted. Check status with etag: #{etag}"
   end

   desc "Submit all metadata for an order. Use storage=glacier for tier 2"
   task :submit_order => :environment do
      o = Order.find(ENV['id'])
      if o.units.any? {|u| u.metadata.children.any?}
         abort("This script does not currently support nested metadata.")
      end
      puts "Publishing all metadata inside order #{o.id} to APTrust, using storage \"#{ENV['storage']}\""

      o.units.each do |unit|
         puts "submitting unit #{unit.id}, updating intended_use: 110"
         unit.update(intended_use_id: 110)
         submit_metadata unit.metadata_id
      end
   end

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
      submit_metadata metadata.id
   end

   desc "Resubmit failed bags"
   task :resubmit_failed  => :environment do
      cnt = 0
      puts "Resend failed submissions"
      Metadata.joins(:ap_trust_status).where("ap_trust_statuses.status=?", "Failed").each do |md|
         puts "   Resubmit failed metadata #{md.id}"
         etag = PublishToApTrust.do_submission(md)
         puts "   Bag submitted. Check status with etag: #{etag}"
         cnt +=1
      end
      puts "DONE. #{cnt} bags re-submitted to APTrust"
   end

   desc "Submit bags for a collection"
   task :submit_collection  => :environment do
      id = ENV['id']
      coll_md = Metadata.find(id)
      puts "Sending children of collection #{coll_md.id}:#{coll_md.title} to APTrust"
      cnt = 0
      coll_md.children.each do |md|
         next if md.preservation_tier_id.blank? || md.preservation_tier_id == 1
         if md.ap_trust_status != nil
            next
         end
         puts "   Submit child metadata #{md.id}"
         etag = PublishToApTrust.do_submission(md)
         puts "   Bag submitted. Check status with etag: #{etag}"
         cnt +=1
      end
      puts "DONE. #{cnt} have been submitted to APTrust"
   end


   desc "Update submitted APTrust status"
   task :update_status => :environment do
      puts "Update status of all Submitted APTrust items.."
      cnt = 0
      pend = 0
      ApTrustStatus.where("status<>? and status<>?", "Submitted", "Failed").each do |apt|
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

   desc "Updates and resubmits bag-info.txt. No files are sent."
   task :reupload_bag_info, [:order_id] => :environment do |task, args|
      ap_trust_statuses = if args[:order_id]
         s = ApTrustStatus.joins(metadata: :units).where(units: {order_id: args[:order_id]} )
         puts "Updating #{s.count} AP Trust bags inside order: #{args[:order_id]}"
         s
      else
         puts "resubmitting bag-info.txt for all submitted items..."
         ApTrustStatus.where("status<>? and status<>?", "Submitted", "Failed")
      end


      ap_trust_statuses.each do |apt|
         metadata = apt.metadata
         storage = "Standard"
         storage = "Glacier-VA" if metadata.preservation_tier_id == 2
         bag = Bagit::Bag.new({bag: "tracksys-#{metadata.type.downcase}-#{metadata.id}",
            title: metadata.title,
            pid: metadata.pid,
            storage: storage,
            collection: metadata.collection_name
            },  Logger.new(STDOUT))

         bag.info_only_adjustments

         tarfile = bag.tar
         etag = ApTrust::submit( tarfile )
         if etag
            puts "Uploaded etag: #{etag}"
            apt.update(etag: etag)
         else
            puts "no etag received for #{apt.metadata_id}"
         end
         bag.cleanup
      end
   end

end
