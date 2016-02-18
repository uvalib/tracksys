class AddJobStatusCounts < ActiveRecord::Migration
  def up
     add_column :bibls, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :components, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :master_files, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :orders, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :units, :job_statuses_count, :integer, :null => false, :default => 0
     add_column :staff_members, :job_statuses_count, :integer, :null => false, :default => 0
  end

  def down
     remove_column :bibls, :job_statuses_count
     remove_column :components, :job_statuses_count
     remove_column :master_files, :job_statuses_count
     remove_column :orders, :job_statuses_count
     remove_column :units, :job_statuses_count
     remove_column :staff_members, :job_statuses_count
  end
end
