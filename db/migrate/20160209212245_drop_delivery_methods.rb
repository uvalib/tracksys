class DropDeliveryMethods < ActiveRecord::Migration
   def up
      if ActiveRecord::Base.connection.table_exists? 'delivery_methods'
         drop_table :delivery_methods_orders
         drop_table :delivery_methods
      end
   end

   def down
      # not reversable
   end
end
