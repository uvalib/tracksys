class CreateLegacyIdentifiersUnitsJoinTable < ActiveRecord::Migration
  def change
    create_table :legacy_identifiers_units, id: false do |t|
      t.integer :legacy_identifier_id
      t.integer :unit_id
    end
    add_index :legacy_identifiers_units, [:unit_id, :legacy_identifier_id], :name => 'units_legacy_ids_index'
  end
end
