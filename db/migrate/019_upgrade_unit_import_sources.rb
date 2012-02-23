class UpgradeUnitImportSources < ActiveRecord::Migration
  def change
    change_table(:unit_import_sources, :bulk => true) do |t|
      t.rename :import_format_software, :standard
      t.rename :import_format_version, :version
      t.rename :import_source, :source
      t.remove :import_format_basis
      t.remove_index :name => 'unit_id'
      t.index :unit_id
      t.foreign_key :units
    end
  end
end
