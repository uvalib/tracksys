class UpgradeBibls < ActiveRecord::Migration
  def change

    add_column :bibls, :date_ingested_into_dl, :datetime
    add_column :bibls, :automation_messages_count, :integer, :default => 0
    add_column :bibls, :orders_count, :integer, :default => 0
    add_column :bibls, :units_count, :integer, :default => 0
    add_column :bibls, :master_files_count, :integer, :default => 0
    add_column :bibls, :availability_policy_id, :integer

    rename_column :bibls, :catalog_id, :catalog_key

    change_column :bibls, :exemplar, :string
    change_column :bibls, :description, :string

    remove_column :bibls, :content_model_id

    add_index :bibls, :barcode
    add_index :bibls, :call_number
    add_index :bibls, :catalog_key
    add_index :bibls, :title
    add_index :bibls, :pid
    add_index :bibls, :parent_bibl_id

    rename_index :bibls, 'indexing_scenario_id', 'index_bibls_on_indexing_scenario_id'
    rename_index :bibls_legacy_identifiers, 'bibl_id', 'index_bibls_legacy_identifiers_on_bibl_id'
    rename_index :bibls_legacy_identifiers, 'legacy_identifier_id', 'index_bibls_legacy_identifiers_on_legacy_identifier_id'
 
    add_foreign_key :bibls, :indexing_scenarios
    add_foreign_key :bibls_legacy_identifiers, :bibls
    add_foreign_key :bibls_legacy_identifiers, :legacy_identifiers

    say "Updating bibl.units_count, bibl.master_files_count, bibl.orders_count and bibl.automation_messages_count"
    Bibl.find(:all).each {|b|
      Bibl.update_counters b.id, :units_count => b.units.count
      Bibl.update_counters b.id, :orders_count => b.orders.count
      Bibl.update_counters b.id, :automation_messages_count => b.automation_messages.count
      Bibl.update_counters b.id, :master_files_count => b.master_files.count
    }
 end
end
