class RemoveUnitImportSource < ActiveRecord::Migration
   def up
      drop_table :unit_import_sources if ActiveRecord::Base.connection.table_exists? 'unit_import_sources'
   end

   def down
      # not reversable
   end
end
