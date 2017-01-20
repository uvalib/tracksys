class DropRoleTable < ActiveRecord::Migration
  def up
     remove_reference  :staff_members, :role, index: true
     drop_table :roles if ActiveRecord::Base.connection.table_exists? 'roles'
  end

  def down
     # NO
  end
end
