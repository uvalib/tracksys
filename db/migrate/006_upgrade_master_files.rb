class UpgradeMasterFiles < ActiveRecord::Migration
  def change
    rename_column :master_files, :name_num, :title
    rename_column :master_files, :staff_notes, :description
    remove_column :master_files, :equipment_id
    remove_column :master_files, :locked_desc_metadata

    add_column :master_files, :availability_policy_id, :integer
    rename_index :master_files, 'component_id', 'index_master_files_on_component_id'
    rename_index :master_files, 'indexing_scenario_id', 'index_master_files_on_indexing_scenario_id'
    rename_index :master_files, 'index_master_files_on_name_num', 'index_master_files_on_title'
    add_index :master_files, :availability_policy_id

    add_foreign_key :master_files, :components
    add_foreign_key :master_files, :indexing_scenarios
    add_foreign_key :master_files, :units
  end
end