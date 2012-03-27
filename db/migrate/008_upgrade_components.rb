class UpgradeComponents < ActiveRecord::Migration
  def change
    change_table(:components, :bulk => true) do |t|
      t.integer :availability_policy_id
      t.datetime :date_dl_ingest
      t.datetime :date_dl_update
      t.integer :use_right_id
      t.integer :master_files_count, :default => 0, :null => false
      t.integer :automation_messages_count, :default => 0, :null => false
      t.remove :bibl_id
      t.remove :label
      t.string :exemplar
      t.remove_index :name => 'component_type_id'
      t.remove_index :name => 'indexing_scenario_id'
      t.index :component_type_id
      t.index :indexing_scenario_id
      t.index :availability_policy_id
      t.index :use_right_id
      t.foreign_key :component_types
      t.foreign_key :indexing_scenarios
      t.foreign_key :availability_policies
      t.foreign_key :use_rights
    end

    # For some reason this won't work in the above change_table method
    change_column_default :components, :discoverability, 1
  end
end
