class UpgradeOrders < ActiveRecord::Migration
  def change
    add_column :orders, :units_count, :integer, :default => 0
    add_column :orders, :master_files_count, :integer, :default => 0
    add_column :orders, :automation_messages_count, :integer, :default => 0
    add_column :orders, :invoices_count, :integer, :default => 0
    
    say "Updating order.units_count, order.invoices_count, order.master_files_count and order.automation_messages_count"
    Order.find(:all).each {|o|
      Order.update_counters o.id, :units_count => o.units.count
      Order.update_counters o.id, :master_files_count => o.master_files.count
      Order.update_counters o.id, :automation_messages_count => o.automation_messages.count
      Order.update_counters o.id, :invoices_count => o.invoices.count
    }

    rename_index :orders, 'dvd_delivery_location_id', 'index_orders_on_dvd_delivery_location_id'
    rename_index :delivery_methods_orders, 'delivery_method_id', 'index_delivery_methods_orders_on_delivery_method_id'
    rename_index :delivery_methods_orders, 'order_id', 'index_delivery_methods_orders_on_order_id'

    add_foreign_key :orders, :agencies
    add_foreign_key :orders, :customers
    add_foreign_key :orders, :dvd_delivery_locations
    
    add_foreign_key :delivery_methods_orders, :delivery_methods
    add_foreign_key :delivery_methods_orders, :orders
  end
end