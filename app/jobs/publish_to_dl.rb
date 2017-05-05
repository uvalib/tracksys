class PublishToDL < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id] )
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'mode' is required" if message[:mode].blank?
      unit = Unit.find(message[:unit_id])
      if message[:mode] == :test
         publish_to_test(unit)
      elsif message[:mode] == :production
         publish_to_prod(unit)
      else
         on_error("Invalid publication mode '#{message[:mode]}' specified")
      end
   end

   def publish_to_prod(unit)
      now = Time.now
      unit.metadata.update(date_dl_update: now)
      unit.master_files.each do |mf|
         mf.update(date_dl_update: now)
         if mf.metadata.id != unit.metadata.id
            if mf.metadata.date_dl_ingest.blank?
               if mf.metadata.date_dl_update.blank?
                  mf.metadata.update(date_dl_ingest: now)
               else
                  mf.metadata.update(date_dl_ingest: mf.metadata.date_dl_update, date_dl_update: now)
               end
            else
               mf.metadata.update(date_dl_update: now)
            end
         end
      end
      logger.info "Unit #{unit.id} and #{unit.master_files_count} master files have been flagged for an update in the DL"
   end

   def publish_to_test(unit)
      if unit.metadata.discoverability
         logger.info "Publish unit ID #{unit.id} to test"
         begin
            unit.metadata.publish_to_test
         rescue Exception=>e
            on_failure("Unable to publish unit #{unit.id} metadata #{unit.metadata.id}: #{e.message}")
         end
      end
      unit.master_files.each do |mf|
         if mf.metadata.discoverability && unit.metadata.id != mf.metadata.id
            logger.info "Publish master file ID #{mf.id} to test"
            begin
               mf.metadata.publish_to_test
            rescue Exception=>e
               on_failure("Unable to publish masterfile #{mf.id} metadata #{mf.metadata.id}: #{e.message}")
            end
         end
      end
   end
end
