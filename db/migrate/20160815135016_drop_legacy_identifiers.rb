class DropLegacyIdentifiers < ActiveRecord::Migration
  def up
     drop_table :legacy_identifiers_units if ActiveRecord::Base.connection.table_exists? 'legacy_identifiers_units'
     drop_table :legacy_identifiers_master_files if ActiveRecord::Base.connection.table_exists? 'legacy_identifiers_master_files'
     drop_table :legacy_identifiers_master_files if ActiveRecord::Base.connection.table_exists? 'legacy_identifiers_master_files'
     drop_table :components_legacy_identifiers if ActiveRecord::Base.connection.table_exists? 'components_legacy_identifiers'
     drop_table :sirsi_metadata_legacy_identifiers if ActiveRecord::Base.connection.table_exists? 'sirsi_metadata_legacy_identifiers'
     drop_table :legacy_identifiers if ActiveRecord::Base.connection.table_exists? 'legacy_identifiers'
  end

  def down
     # not reversable
  end
end
