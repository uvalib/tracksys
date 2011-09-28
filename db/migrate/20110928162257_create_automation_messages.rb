class CreateAutomationMessages < ActiveRecord::Migration
  def change
    create_table :automation_messages do |t|
      t.integer :unit_id
      t.integer :order_id
      t.integer :master_file_id
      t.integer :bibl_id
      t.integer :ead_ref_id
      t.integer :component_id
      t.boolean :active_error, :null => false, :default => 0
      t.string :pid
      t.string :app
      t.string :processor
      t.string :message_type
      t.string :workflow_type
      t.text :message
      t.text :class_name
      t.text :backtrace
      t.timestamps
    end
    add_index :automation_messages, :unit_id
    add_index :automation_messages, :order_id
    add_index :automation_messages, :processor
    add_index :automation_messages, :message_type
    add_index :automation_messages, :workflow_type
    add_index :automation_messages, :active_error
    add_index :automation_messages, :master_file_id
    add_index :automation_messages, :bibl_id
    add_index :automation_messages, :component_id
    add_index :automation_messages, :ead_ref_id  
    add_index :automation_messages, [ :unit_id, :message_type]
    add_index :automation_messages, [ :unit_id, :processor]
    add_index :automation_messages, [ :order_id, :message_type]
    add_index :automation_messages, [ :order_id, :processor]
    add_index :automation_messages, [ :master_file_id, :message_type]
    add_index :automation_messages, [ :master_file_id, :processor]
    add_index :automation_messages, [ :bibl_id, :message_type]
    add_index :automation_messages, [ :bibl_id, :processor]
    add_index :automation_messages, [ :ead_ref_id, :message_type]
    add_index :automation_messages, [ :ead_ref_id, :processor]
    add_index :automation_messages, [ :component_id, :message_type]
    add_index :automation_messages, [ :component_id, :processor]
    add_index :automation_messages, [ :processor, :message_type]
    add_index :automation_messages, [ :unit_id, :processor, :message_type], :name => 'index_by_unit_processor_message_type'
    add_index :automation_messages, [ :order_id, :processor, :message_type], :name => 'index_by_order_processor_message_type'
    add_index :automation_messages, [ :master_file_id, :processor, :message_type], :name => 'index_by_master_file_processor_message_type'
    add_index :automation_messages, [ :bibl_id, :processor, :message_type], :name => 'index_by_bibl_processor_message_type'
    add_index :automation_messages, [ :component_id, :processor, :message_type], :name => 'index_by_component_processor_message_type'
    add_index :automation_messages, [ :ead_ref_id, :processor, :message_type], :name => 'index_by_ead_processor_message_type'
    add_index :automation_messages, [ :unit_id, :processor, :workflow_type], :name => 'index_by_unit_processor_workflow_type'
    add_index :automation_messages, [ :order_id, :processor, :workflow_type], :name => 'index_by_order_processor_workflow_type'
    add_index :automation_messages, [ :master_file_id, :processor, :workflow_type], :name => 'index_by_master_file_processor_workflow_type'
    add_index :automation_messages, [ :bibl_id, :processor, :workflow_type], :name => 'index_by_bibl_processor_workflow_type'
    add_index :automation_messages, [ :component_id, :processor, :workflow_type], :name => 'index_by_component_processor_workflow_type'
    add_index :automation_messages, [ :ead_ref_id, :processor, :workflow_type], :name => 'index_by_ead_processor_workflow_type'
  end
end