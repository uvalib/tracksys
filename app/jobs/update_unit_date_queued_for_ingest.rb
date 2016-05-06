class UpdateUnitDateQueuedForIngest < BaseJob

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit_id = message[:unit_id]
      source = message[:source]
      unit = Unit.find(unit_id)
      unit.update_attribute(:date_queued_for_ingest, Time.now)

      on_success "Date queued for ingest for Unit #{unit_id} has been updated."
      QueueObjectsForFedora.exec_now({ :unit => unit, :source => source }, self)
   end
end
