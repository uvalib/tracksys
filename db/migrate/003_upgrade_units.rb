class UpgradeUnits < ActiveRecord::Migration
  def change
    remove_column :units, :fasttrack
    remove_column :units, :vendor_batch_id
  	remove_column :units, :content_model_id

    add_column :units, :availability_policy_id, :integer
    add_column :units, :master_files_count, :integer, :default => 0
    add_column :units, :automation_messages_count, :integer, :default => 0
    add_column :units, :master_file_discoverability, :boolean, :null => false, :default => 0

    say "Updating unit.master_files_count"
    Unit.find(:all).each {|u|
      Unit.update_counters u.id, :master_files_count => u.master_files.count
      Unit.update_counters u.id, :automation_messages_count => u.automation_messages.count
    }

    rename_index :units, 'archive_id', 'index_units_on_archive_id'
    rename_index :units, 'heard_about_resource_id', 'index_units_on_heard_about_resource_id'
    rename_index :units, 'indexing_scenario_id', 'index_units_on_indexing_scenario_id'

    add_index :units, :date_dl_deliverables_ready
    add_index :units, :use_right_id

    add_foreign_key :units, :archives
    add_foreign_key :units, :bibls
    add_foreign_key :units, :heard_about_resources
    add_foreign_key :units, :indexing_scenarios
    add_foreign_key :units, :intended_uses
    add_foreign_key :units, :orders
    add_foreign_key :units, :use_rights
  end
end