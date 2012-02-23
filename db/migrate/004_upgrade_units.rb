class UpgradeUnits < ActiveRecord::Migration
  def change
    change_table(:units, :bulk => true) do |t|
      t.remove :fasttrack
      t.remove :vendor_batch_id
      t.remove :content_model_id
      t.remove :transcription_destination
      t.remove :transcription_format
      t.remove :transcription_vendor_invoice_num
      t.remove :date_transcription_deliverables_ready
      t.remove :date_transcription_deliverables_sent_to_vendor
      t.remove :date_transcription_returned_from_vendor
      t.remove :date_cataloging_notification_sent
      t.remove :priority
      t.integer :availability_policy_id
      t.integer :master_files_count, :default => 0
      t.integer :automation_messages_count, :default => 0
      t.boolean :master_file_discoverability, :null => false, :default => 0
      t.change :bibl_id, :integer
      t.rename :url, :patron_source_url
      t.remove_index :name => 'archive_id'
      t.remove_index :name => 'heard_about_resource_id'
      t.remove_index :name => 'indexing_scenario_id'
      t.remove_index :name => 'use_right_id'
      t.index :archive_id
      t.index :indexing_scenario_id
      t.index :use_right_id
      t.index :heard_about_resource_id
      t.index :date_dl_deliverables_ready
      t.index :availability_policy_id
      t.foreign_key :availability_policies
      t.foreign_key :archives
      t.foreign_key :bibls
      t.foreign_key :heard_about_resources
      t.foreign_key :indexing_scenarios
      t.foreign_key :intended_uses
      t.foreign_key :orders
      t.foreign_key :use_rights
    end
  end
end
