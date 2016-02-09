class RemoveSessionTable < ActiveRecord::Migration
  def change
     drop_table :sessions
  end
end
