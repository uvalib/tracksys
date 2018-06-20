class ChangeJobStatusErrorToText < ActiveRecord::Migration[5.2]
   def up
      change_column :job_statuses, :error, :text
   end

   def down

      # create a temporary column to hold the truncated values
      add_column :job_statuses, :tmp_error, :string

      JobStatus.find_each do |js|
         # get the current error and truncate down to 255 if needed
         working_err = js.error
         if working_err.length > 255
            working_err = working_err[0,254]
         end

         # use #update_column because it skips validations AND callbacks
         js.update_column(:tmp_error, working_err)
      end

      # Now delete the old and rename temp as it has the truncated data
      remove_column :job_statuses, :error
      rename_column :job_statuses, :tmp_error, :error
   end
end
