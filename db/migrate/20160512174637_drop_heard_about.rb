class DropHeardAbout < ActiveRecord::Migration
   def up
      remove_foreign_key :customers, :heard_about_service
      remove_column :customers, :heard_about_service_id
      remove_foreign_key :units, :heard_about_resource
      remove_column :units, :heard_about_resource_id
      drop_table :heard_about_resources if ActiveRecord::Base.connection.table_exists? 'heard_about_resources'
      drop_table :heard_about_services if ActiveRecord::Base.connection.table_exists? 'heard_about_services'
   end

   def down
      # not reversable
   end
end
