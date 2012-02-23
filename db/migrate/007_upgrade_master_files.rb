class UpgradeMasterFiles < ActiveRecord::Migration
  def change
    change_table(:master_files, :bulk => true) do |t|
      t.remove_index :name_num
      t.rename :name_num, :title
      t.rename :staff_notes, :description
      t.remove :equipment_id
      t.remove :locked_desc_metadata
      t.remove :file_id_ref
      t.remove :screen_preview
      t.integer :availability_policy_id
      t.integer :automation_messages_count, :default => 0
      t.integer :use_right_id
      t.datetime :date_ingested_into_dl
      t.remove_index :name => 'component_id'
      t.remove_index :name => 'indexing_scenario_id'
      t.index :availability_policy_id
      t.index :component_id
      t.index :indexing_scenario_id
      t.index :title
      t.index :use_right_id
      t.foreign_key :availability_policies
      t.foreign_key :components
      t.foreign_key :indexing_scenarios
      t.foreign_key :units
      t.foreign_key :use_rights
    end

    # Since I cannot figure out how to rename a column and change its type in the same transaction,
    # I've resorted to a second change_table block.  Argh!
    change_table(:master_files) do |t|
      t.change :description, :string
    end

    # TODO: Populate master_file.date_ingested_into_dl from master_file.unit.date_dl_deliverables_ready
  end
end
