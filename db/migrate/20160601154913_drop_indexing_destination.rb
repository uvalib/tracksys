class DropIndexingDestination < ActiveRecord::Migration
   def up
      remove_column :bibls, :index_destination_id
      remove_column :components, :index_destination_id
      remove_column :units, :index_destination_id

      drop_table :index_destinations if ActiveRecord::Base.connection.table_exists? 'index_destinations'
   end

   def down
      # not reversable
   end
end
