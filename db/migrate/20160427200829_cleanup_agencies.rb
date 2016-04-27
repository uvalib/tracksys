class CleanupAgencies < ActiveRecord::Migration
  def up
     remove_column :agencies, :first_name
     remove_column :agencies, :last_name
     remove_column :agencies, :is_billable
  end

  def down
     add_column :agencies, :first_name, :string
     add_column :agencies, :last_name, :string
     add_column :agencies, :is_billable, :boolean
  end
end
