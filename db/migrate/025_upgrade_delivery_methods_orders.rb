class UpgradeDeliveryMethodsOrders < ActiveRecord::Migration
  def change
    change_table(:delivery_methods_orders, :bulk => true) do |t|
      t.remove_index :name => 'delivery_method_id'
      t.index :delivery_method_id
      t.remove_index :name => 'order_id'
      t.index :order_id
      t.foreign_key :delivery_methods
      t.foreign_key :orders
    end
  end
end
