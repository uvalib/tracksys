class UpdateUnitDateQueuedForIngest < BaseJob

   def do_workflow(message)
      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source' is required" if message[:source].blank?

      unit = message[:unit]
      source = message[:source]
      unit.update_attribute(:date_queued_for_ingest, Time.now)

      on_success "Date queued for ingest for Unit #{unit.id} has been updated."
      QueueObjectsForFedora.exec_now({ :unit => unit, :source => source }, self)
   end
end
