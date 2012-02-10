class UpgradeLegacyIdentifiersMasterFiles < ActiveRecord::Migration
  def change
    rename_index :legacy_identifiers_master_files, 'legacy_identifier_id', 'index_legacy_identifiers_master_files_on_legacy_identifier_id'
    rename_index :legacy_identifiers_master_files, 'master_file_id', 'index_legacy_identifiers_master_files_on_master_file_id'
    
    add_foreign_key :legacy_identifiers_master_files, :master_files
    add_foreign_key :legacy_identifiers_master_files, :legacy_identifiers
  end
end