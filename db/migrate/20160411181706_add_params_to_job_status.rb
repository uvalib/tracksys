class AddParamsToJobStatus < ActiveRecord::Migration
   def up
      add_column :job_statuses, :params, :string
   end

   def down
      remove_column :job_statuses, :params
   end
end
