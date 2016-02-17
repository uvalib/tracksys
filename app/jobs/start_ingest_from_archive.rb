class StartIngestFromArchive < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)
      if message[:unit_id]
         @unit_id = message[:unit_id]
         @unit_dir = "%09d" % @unit_id
         @working_unit = Unit.find(@unit_id)
         @source = File.join(ARCHIVE_DIR, @unit_dir)
         on_success "The DL ingestion workflow for Unit #{@unit_id} has begun."
         UpdateUnitDateQueuedForIngest.exec_now({ :unit_id => @unit_id, :source => @source}, self)
      else
         ingestable_units = Unit.find(:all, :conditions => "include_in_dl = '1' AND date_queued_for_ingest IS NULL AND availability IS NOT NULL and date_archived IS NOT NULL")

         ingestable_units.each do |ingestable_unit|
            @unit_id = ingestable_unit.id
            @unit_dir = "%09d" % @unit_id
            @working_unit = Unit.find(@unit_id)
            @source = File.join(ARCHIVE_DIR, @unit_dir)
            on_success "The DL ingestion workflow for Unit #{@unit_id} has begun."
            UpdateUnitDateQueuedForIngest.exec_now({ :unit_id => @unit_id, :source => @source}, self)
         end
      end
   end
end
