class UpgradeUnits < ActiveRecord::Migration
  def change
    remove_column :units, :fasttrack
    remove_column :units, :vendor_batch_id
    remove_column :units, :content_model_id
    remove_column :units, :transcription_destination
    remove_column :units, :transcription_format
    remove_column :units, :transcription_vendor_invoice_num
    remove_column :units, :date_transcription_deliverables_ready
    remove_column :units, :date_transcription_deliverables_sent_to_vendor
    remove_column :units, :date_transcription_returned_from_vendor
    remove_column :units, :date_cataloging_notification_sent
    remove_column :units, :priority

    add_column :units, :availability_policy_id, :integer
    add_column :units, :master_files_count, :integer, :default => 0
    add_column :units, :automation_messages_count, :integer, :default => 0
    add_column :units, :master_file_discoverability, :boolean, :null => false, :default => 0

    change_column :units, :bibl_id, :integer

    rename_column :units, :url, :patron_source_url

    say "Updating unit.master_files_count"
    Unit.find(:all).each {|u|
      Unit.update_counters u.id, :master_files_count => u.master_files.count
      Unit.update_counters u.id, :automation_messages_count => u.automation_messages.count
    }

    rename_index :units, 'archive_id', 'index_units_on_archive_id'
    rename_index :units, 'heard_about_resource_id', 'index_units_on_heard_about_resource_id'
    rename_index :units, 'indexing_scenario_id', 'index_units_on_indexing_scenario_id'
    rename_index :units, 'use_right_id', 'index_units_on_use_right_id'

    add_index :units, :date_dl_deliverables_ready

    add_foreign_key :units, :archives
    add_foreign_key :units, :bibls
    add_foreign_key :units, :heard_about_resources
    add_foreign_key :units, :indexing_scenarios
    add_foreign_key :units, :intended_uses
    add_foreign_key :units, :orders
    add_foreign_key :units, :use_rights
  end
end