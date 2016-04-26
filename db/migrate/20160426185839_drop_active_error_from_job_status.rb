class DropActiveErrorFromJobStatus < ActiveRecord::Migration
  def up
     remove_column :job_statuses, :active_error
     remove_column :bibls, :job_statuses_count
     remove_column :components, :job_statuses_count
     remove_column :master_files, :job_statuses_count
     remove_column :orders, :job_statuses_count
     remove_column :units, :job_statuses_count
     remove_column :staff_members, :job_statuses_count
  end

  def down
     add_column :job_statuses, :active_error, :boolean, :default=>false
     add_column :bibls, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :components, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :master_files, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :orders, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :units, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :staff_members, :job_statuses_count, :integer, :null => false, :default => 0
  end
end
