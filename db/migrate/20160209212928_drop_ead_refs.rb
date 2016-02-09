class DropEadRefs < ActiveRecord::Migration
   def change
      drop_table :bibls_ead_refs
      drop_table :ead_refs_master_files
      drop_table :ead_refs
   end
end
