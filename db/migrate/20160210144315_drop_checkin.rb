class DropCheckin < ActiveRecord::Migration
   def up
      drop_table :checkins if ActiveRecord::Base.connection.table_exists? 'checkins'
   end

   def down
      # not reversable
   end
end
