class DropDeliveryMethods < ActiveRecord::Migration
   def change

      drop_table :delivery_methods_orders
      drop_table :delivery_methods
   end
end
