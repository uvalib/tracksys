class UpgradeInvoices < ActiveRecord::Migration
  def change
    rename_index :invoices, 'order_id', 'index_invoices_on_order_id'
    add_foreign_key :invoices, :orders
  end
end
