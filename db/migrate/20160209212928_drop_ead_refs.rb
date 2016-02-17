class DropEadRefs < ActiveRecord::Migration
   def up
      if ActiveRecord::Base.connection.table_exists? 'ead_refs'
         drop_table :bibls_ead_refs
         drop_table :ead_refs_master_files
         drop_table :ead_refs
      end
   end

   def down
      # not reversable
   end
end
