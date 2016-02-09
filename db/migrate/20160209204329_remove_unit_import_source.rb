class RemoveUnitImportSource < ActiveRecord::Migration
   def up
      drop_table :unit_import_sources
   end

   def down
      create_table :unit_import_sources do |t|
         t.integer :unit_id
         t.string :standard
         t.string :version
         t.text :source
      end
   end
end
