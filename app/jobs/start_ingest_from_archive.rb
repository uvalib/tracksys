class StartIngestFromArchive < BaseJob

   def perform(message)
      if message[:unit_id]
         @unit_id = message[:unit_id]
         @unit_dir = "%09d" % @unit_id
         @working_unit = Unit.find(@unit_id)
         @messagable_id = @unit_id
         @messagable_type = "Unit"
         set_workflow_type()

         # Check to make sure that the Unit has been archived to a mounted Archive
         if @working_unit.archive.directory?
            @source = File.join(@working_unit.archive.directory, @unit_dir)
            on_success "The DL ingestion workflow for Unit #{@unit_id} has begun."
            UpdateUnitDateQueuedForIngest.exec_now({ :unit_id => @unit_id, :source => @source})
         else
            on_error "Unit #{@unit_id} has no directory from which to fetch material.  Check archival storage."
         end
      else
         ingestable_units = Unit.find(:all, :conditions => "include_in_dl = '1' AND date_queued_for_ingest IS NULL AND availability IS NOT NULL and date_archived IS NOT NULL")

         ingestable_units.each {|ingestable_unit|
            @unit_id = ingestable_unit.id
            @unit_dir = "%09d" % @unit_id
            @working_unit = Unit.find(@unit_id)
            @messagable_id = @unit_id
            @messagable_type = "Unit"
            set_workflow_type()

            # Check to make sure that the Unit has been archived to a mounted Archive
            if @working_unit.archive.directory?
               @source = File.join(@working_unit.archive.directory, @unit_dir)
               on_success "The DL ingestion workflow for Unit #{@unit_id} has begun."
               UpdateUnitDateQueuedForIngest.exec_now({ :unit_id => @unit_id, :source => @source})
            else
               on_error "Unit #{@unit_id} has no directory from which to fetch material.  Check archival storage."
            end
         }
      end
   end
end
