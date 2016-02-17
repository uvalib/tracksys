class DropAdminUser < ActiveRecord::Migration
  def up
     drop_table :admin_users if ActiveRecord::Base.connection.table_exists? 'admin_users'
  end

  def down
     #not reversable
  end
end
