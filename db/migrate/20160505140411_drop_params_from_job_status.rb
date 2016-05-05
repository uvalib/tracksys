class DropParamsFromJobStatus < ActiveRecord::Migration
  def change
     remove_column :job_statuses, :params
  end
end
