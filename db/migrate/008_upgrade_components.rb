class UpgradeComponents < ActiveRecord::Migration
  def change
    change_table(:components, :bulk => true) do |t|
      t.integer :availability_policy_id
      t.datetime :date_ingested_into_dl
      t.integer :use_right_id
      t.integer :master_files_count, :default => 0, :null => false
      t.remove_index :name => 'bibl_id'
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
  end
end
