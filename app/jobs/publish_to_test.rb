class PublishToTest < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]
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
