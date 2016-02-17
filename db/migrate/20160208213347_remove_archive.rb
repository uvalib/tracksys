class RemoveArchive < ActiveRecord::Migration
   def up
      if ActiveRecord::Base.connection.table_exists? 'archives'
         remove_foreign_key :units, :archive
         remove_column :units, :archive_id
         drop_table :archives
      end
   end

   def down
      # not reversable
   end
end
