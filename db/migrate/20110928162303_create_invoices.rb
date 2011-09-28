class CreateInvoices < ActiveRecord::Migration
  def change
    create_table :invoices do |t|
      t.integer :order_id
      t.datetime :date_invoice_sent
      t.decimal :fee_amount_paid
      t.datetime :date_second_invoice_sent
      t.text :notes
      t.binary :invoice_copy, :limit => 2.megabytes

      t.timestamps
    end

    add_index :invoices, :order_id
  end
end