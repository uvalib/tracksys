class UpgradeComponents < ActiveRecord::Migration
  def change
    add_column :components, :availability_policy_id, :integer

    remove_index :components, :name => 'bibl_id'
    remove_index :components, :name => 'component_type_id'
    remove_index :components, :name => 'indexing_scenario_id'

    add_index :components, :component_type_id
    add_index :components, :indexing_scenario_id

    add_foreign_key :components, :component_types
    add_foreign_key :components, :indexing_scenarios
  end
end
