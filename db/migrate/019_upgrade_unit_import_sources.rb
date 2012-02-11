class UpgradeUnitImportSources < ActiveRecord::Migration

  def change
    rename_column :unit_import_sources, :import_format_software, :standard
    rename_column :unit_import_sources, :import_format_version, :version
    rename_column :unit_import_sources, :import_source, :source
    remove_column :unit_import_sources, :import_format_basis

    rename_index :unit_import_sources, 'unit_id', 'index_unit_import_sources_on_unit_id'

    add_foreign_key :unit_import_sources, :units

  end
end