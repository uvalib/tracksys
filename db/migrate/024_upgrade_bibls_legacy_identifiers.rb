class UpgradeBiblsLegacyIdentifiers < ActiveRecord::Migration
  def change
    change_table(:bibls_legacy_identifiers, :bulk => true) do |t|
      t.remove_index :name => 'bibl_id'
      t.index :bibl_id
      t.remove_index :name => 'legacy_identifier_id'
      t.index :legacy_identifier_id
      t.foreign_key :bibls
      t.foreign_key :legacy_identifiers
    end
  end
end