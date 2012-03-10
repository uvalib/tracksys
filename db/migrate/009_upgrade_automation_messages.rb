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

    # Transition all legacy *_id to messagable_id and messagable_type
    AutomationMessage.where('bibl_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Bibl")
      am.update_attribute(:messagable_id, am.bibl_id)
    end

    AutomationMessage.where('order_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Order")
      am.update_attribute(:messagable_id, am.order_id)
    end

    AutomationMessage.where('component_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Component")
      am.update_attribute(:messagable_id, am.component_id)
    end

    AutomationMessage.where('master_file_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "MasterFile")
      am.update_attribute(:messagable_id, am.master_file_id)
    end

    AutomationMessage.where('unit_id is not null').find_each(:batch_size => 50000) do |am|
      am.update_attribute(:messagable_type, "Unit")
      am.update_attribute(:messagable_id, am.unit_id)
    end

    AutomationMessage.where('bibl_id is not null').update_all( :bibl_id => nil )
    AutomationMessage.where('order_id is not null').update_all( :order_id => nil )
    AutomationMessage.where('component_id is not null').update_all( :component_id => nil )
    AutomationMessage.where('master_file_id is not null').update_all( :master_file_id => nil )
    AutomationMessage.where('unit_id is not null').update_all( :unit_id => nil )

  end
end
