class StartIngestFromArchive < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)
      raise "Parameter 'unit_id' is required" if message[:unit_id].nil?
      unit_id = message[:unit_id]
      unit_dir = "%09d" % unit_id
      source = File.join(ARCHIVE_DIR, unit_dir)
      on_success "The DL ingestion workflow for Unit #{unit_id} has begun."
      UpdateUnitDateQueuedForIngest.exec_now({ :unit_id => unit_id, :source => source}, self)
   end
end
