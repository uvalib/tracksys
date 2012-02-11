 class UpgradeAutomationMessages < ActiveRecord::Migration
  def change
    add_column :automation_messages, :workflow_type, :string
    add_index :automation_messages, :workflow_type
    change_column :automation_messages, :active_error, :boolean, :null => false, :default => 0
    change_column :automation_messages, :message, :string
    
    # Update all existing automation workflow_type based on processor name
    # AutomationMessage.find(:all).each {|am|
    # }

    # The need to keep this in the migration is dependent on Matthew's removal of it before the migration.
    remove_column :automation_messages, :ead_ref_id

    add_foreign_key :automation_messages, :bibls
    add_foreign_key :automation_messages, :components
    add_foreign_key :automation_messages, :master_files
    add_foreign_key :automation_messages, :orders
    add_foreign_key :automation_messages, :units
  end
end
