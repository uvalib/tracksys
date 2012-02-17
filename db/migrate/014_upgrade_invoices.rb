class UpgradeInvoices < ActiveRecord::Migration
  def change
    change_table(:invoices, :bulk => true) do |t|
      t.remove_index :name => 'order_id'
      t.index :order_id
      t.foreign_key :orders
    end
  end
end
