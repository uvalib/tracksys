class PublishToTest < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      unit = message[:unit]
      if unit.metadata.discoverability
        unit.metadata.publish_to_test
     end
     unit.master_files.each do |mf|
        if mf.metadata.discoverability && unit.metadata.id != mf.metadata.id
           mf.metadata.publish_to_test
        end
     end
   end
end
