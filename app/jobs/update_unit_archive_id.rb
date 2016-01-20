class UpdateUnitArchiveId < BaseJob

   def perform(message)
      Job_Log.debug "UpdateUnitArchiveIdProcessor received: #{message.to_json}"

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'source_dir' is required" if message[:source_dir].blank?

      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()

      @unit_id = message[:unit_id]
      @source_dir = message[:source_dir]

      # Update archive location.  Current location set to Archives.find(5) which is the
      # temporary Stornext replacement archive.
      @working_unit = Unit.find(@unit_id)
      @working_unit.update_attribute(:archive_id, 5)

      UpdateUnitDateArchived.exec_now({ :unit_id => @unit_id, :source_dir => @source_dir })
      on_success "Unit archive id has been updated for unit #{@unit_id}."
   end
end
