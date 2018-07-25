class DeleteUnusedOrderFields < ActiveRecord::Migration[5.2]
  def up
     puts "Updating orders that have a fee_estimated but not a fee_actual..."
     update_q = "update orders set fee_actual = fee_estimated where fee_actual is null and fee_estimated is not null"
     Order.connection.execute(update_q)

     puts "Updating order structure..."
     remove_column :orders, :fee_estimated, :decimal, precision: 7, scale: 2
     rename_column :orders, :fee_actual, :fee
     remove_column :invoices, :invoice_number, :integer

     puts "DONE!"
  end

  def down
     add_column :invoices, :invoice_number, :integer
     rename_column :orders, :fee, :fee_actual
     add_column :orders, :fee_estimated, :decimal, precision: 7, scale: 2
  end
end
