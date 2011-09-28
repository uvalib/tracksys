class CreateLegacyIdentifiers < ActiveRecord::Migration
  def change
    create_table :legacy_identifiers do |t|

      t.timestamps
    end
  end
end
