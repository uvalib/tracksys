class UpgradeLegacyIdentifiersMasterFiles < ActiveRecord::Migration
  def change
    change_table(:legacy_identifiers_master_files, :bulk => true) do |t|
      t.remove_index :name => 'legacy_identifier_id'
      t.remove_index :name => 'master_file_id'
      t.index :legacy_identifier_id
      t.index :master_file_id
      t.foreign_key :master_files
      t.foreign_key :legacy_identifiers
    end
  end
end
