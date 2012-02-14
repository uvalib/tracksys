class UpgradeOrders < ActiveRecord::Migration
  def change
    add_column :orders, :units_count, :integer, :default => 0
    add_column :orders, :automation_messages_count, :integer, :default => 0
    add_column :orders, :invoices_count, :integer, :default => 0

    change_column :orders, :date_due, :date
    
    say "Updating order.units_count, order.invoices_count, and order.automation_messages_count"
    Order.find(:all).each {|o|
      Order.update_counters o.id, :units_count => o.units.count
      Order.update_counters o.id, :automation_messages_count => o.automation_messages.count
      Order.update_counters o.id, :invoices_count => o.invoices.count
    }

    say "Consolidating order.staff_notes and order.status_notes into order.staff_notes"
    Order.where('status_notes is not null').each {|o|
      o.staff_notes.to_s << "  #{o.status_notes.to_s}"
      o.save
    }

    remove_column :orders, :status_notes

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