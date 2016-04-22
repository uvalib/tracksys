class DropAutomationMessages < ActiveRecord::Migration
  def up
     remove_column :bibls, :automation_messages_count
     remove_column :components, :automation_messages_count
     remove_column :master_files, :automation_messages_count
     remove_column :orders, :automation_messages_count
     remove_column :units, :automation_messages_count
     remove_column :staff_members, :automation_messages_count

     drop_table :automation_messages
  end

  def down
     # not reversable
  end
end
