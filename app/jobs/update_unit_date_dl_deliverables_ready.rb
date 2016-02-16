class UpdateUnitDateDlDeliverablesReady < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Unit", :originator_id=>message[:unit_id])
   end

   def do_workflow(message)

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      @unit_id = message[:unit_id]
      @working_unit = Unit.find(@unit_id)
      @messagable = @working_unit
      @working_unit.update_attribute(:date_dl_deliverables_ready, Time.now)

      SendCommitToSolr.exec_now({ :unit_id => @unit_id }, self)

      on_success "Unit #{@unit_id} has completed ingestion to #{FEDORA_REST_URL}."
   end
end
