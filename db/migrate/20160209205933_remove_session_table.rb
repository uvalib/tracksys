class RemoveSessionTable < ActiveRecord::Migration
  def up
     drop_table :sessions if ActiveRecord::Base.connection.table_exists? 'sessions'
  end

  def down
     # not reversable
  end
end
