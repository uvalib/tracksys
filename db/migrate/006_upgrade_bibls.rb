class UpgradeBibls < ActiveRecord::Migration
  def change
    change_table(:bibls, :bulk => true) do |t|
      t.datetime :date_ingested_into_dl
      t.integer :automation_messages_count, :default => 0
      t.integer :orders_count, :default => 0
      t.integer :units_count, :default => 0
      t.integer :master_files_count, :default => 0
      t.integer :availability_policy_id
      t.rename :catalog_id, :catalog_key
      t.change :exemplar, :string
      t.change :description, :string
      t.remove :content_model_id
      t.index :barcode
      t.index :call_number
      t.index :catalog_key
      t.index :title
      t.index :pid
      t.index :parent_bibl_id
      t.remove_index :name => 'indexing_scenario_id'
      t.index :indexing_scenario_id
      t.index :availability_policy_id
      t.foreign_key :indexing_scenarios
      t.foreign_key :availability_policies
    end
 end
end
