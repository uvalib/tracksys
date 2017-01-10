class DropItems < ActiveRecord::Migration
   def up
      remove_reference :master_files, :item, index: true
      drop_table :items if ActiveRecord::Base.connection.table_exists? 'items'
   end

   def down
      # not reversable
   end
end
