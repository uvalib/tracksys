class UpdateUnitDatePatronDeliverablesReady < BaseJob
   def perform(message)
      Job_Log.debug "UpdateUnitDatePatronDeliverablesProcessor received: #{message.to_json}"

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()
      @unit_id = message[:unit_id]
      @working_unit = Unit.find(@unit_id)
      @messagable = @working_unit
      @working_unit.update_attribute(:date_patron_deliverables_ready, Time.now)
      on_success "Date patron deliverables ready for unit #{@unit_id} has been updated."
   end
end
