class UpdateUnitDateArchived < BaseJob

   def do_workflow(message)

      raise "Parameter 'unit' is required" if message[:unit].blank?
      raise "Parameter 'source_dir' is required" if message[:source_dir].blank?

      unit = message[:unit]
      source_dir = message[:source_dir]
      unit.update_attribute(:date_archived, Time.now)
      unit.master_files.each do |mf|
         mf.update_attributes(:date_archived => Time.now)
      end

      CheckOrderDateArchivingComplete.exec_now({ :unit => unit }, self)

      # Now that all archiving work for the unit is done, it (and any subsidary files) must be moved to the ready_to_delete directory
      MoveCompletedDirectoryToDeleteDirectory.exec_now({ :unit_id => unit.id, :source_dir => source_dir}, self)

      on_success "Date Archived updated for for unit #{unit.id}"
   end
end
