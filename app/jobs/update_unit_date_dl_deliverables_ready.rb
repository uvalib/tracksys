class UpdateUnitDateDlDeliverablesReady < BaseJob

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  def perform(message)
    Job_Log.debug "UpdateUnitDateDlDeliverablesProcessor received: #{message.to_json}"

    raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
    @messagable_id = message[:unit_id]
    @messagable_type = "Unit"
    set_workflow_type()

    @unit_id = message[:unit_id]

    @working_unit = Unit.find(@unit_id)
    @messagable = @working_unit
    @working_unit.update_attribute(:date_dl_deliverables_ready, Time.now)

    SendCommitToSolr.exec_now({ :unit_id => @unit_id })

    on_success "Unit #{@unit_id} has completed ingestion to #{FEDORA_REST_URL}."
  end
end
