class AddRoleToStaffMember < ActiveRecord::Migration
  def up
     add_column :staff_members, :role, :string, :null => false, :default => 'admin'
  end

  def down
     remove_column :staff_members, :role
  end
end
