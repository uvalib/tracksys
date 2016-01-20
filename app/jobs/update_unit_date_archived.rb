class UpdateUnitDateArchived < BaseJob

   def perform(message)
      Job_Log.debug "UpdateUnitDateArchivedProcessor received: #{message.to_json}"

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'source_dir' is required" if message[:source_dir].blank?

      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()
      @unit_id = message[:unit_id]
      @source_dir = message[:source_dir]
      @working_unit = Unit.find(@unit_id)
      @working_unit.update_attribute(:date_archived, Time.now)
      @working_unit.master_files.each do |mf|
         mf.update_attributes(:date_archived => Time.now)
      end

      CheckOrderDateArchivingCompleteProcessor.exec_now({ :unit_id => @unit_id })

      # Now that all archiving work for the unit is done, it (and any subsidary files) must be moved to the ready_to_delete directory
      MoveCompletedDirectoryToDeleteDirectory.exec_now({ :unit_id => @unit_id, :source_dir => @source_dir})

      on_success "Date Archived updated for for unit #{@unit_id}"
   end
end
