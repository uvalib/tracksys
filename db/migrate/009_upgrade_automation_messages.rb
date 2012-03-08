 class UpgradeAutomationMessages < ActiveRecord::Migration
  def change
    change_table(:automation_messages, :bulk => true) do |t|
      t.integer :messagable_id, :null => false
      t.string :messagable_type, :null => false, :limit => 20

      t.string :workflow_type
      t.index :workflow_type
      t.change :active_error, :boolean, :null => false, :default => 0
      t.change :message, :string
      t.remove :ead_ref_id
      t.foreign_key :bibls
      t.foreign_key :components
      t.foreign_key :master_files
      t.foreign_key :orders
      t.foreign_key :units
    end
    
    # TODO: Update all existing automation workflow_type based on processor name
    # AutomationMessage.find(:all).each {|am|
    # }
  end
end
