class UpdateUnitDateQueuedForIngest < BaseJob

   def perform(message)
      Job_Log.debug "UpdateUnitDateQueuedForIngestProcessor received: #{message.to_s}"

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'source' is required" if message[:source].blank?
      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()

      @unit_id = message[:unit_id]
      @source = message[:source]

      @working_unit = Unit.find(@unit_id)
      @messagable = @working_unit
      @working_unit.update_attribute(:date_queued_for_ingest, Time.now)

      QueueObjectsForFedora.exec_now({ :unit_id => @unit_id, :source => @source })
      on_success "Date queued for ingest for Unit #{@unit_id} has been updated."
   end
end
