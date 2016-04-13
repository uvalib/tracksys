class DropVersions < ActiveRecord::Migration
   def up
      drop_table :versions
   end

   def down
      # not reversable
   end
end
