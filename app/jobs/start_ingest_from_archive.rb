class StartIngestFromArchive < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit].id )
   end

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].nil?
      unit = message[:unit]
      unit_dir = "%09d" % unit.id
      source = File.join(ARCHIVE_DIR, unit_dir)
      on_success "The DL ingestion workflow for Unit #{unit.id} has begun."
      CreateDlDeliverables.exec_now({ :unit => unit, :source => source}, self)
   end
end
