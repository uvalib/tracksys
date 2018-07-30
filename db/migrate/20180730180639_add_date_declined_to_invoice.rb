class AddDateDeclinedToInvoice < ActiveRecord::Migration[5.2]
  def change
     add_column :invoices, :date_fee_declined, :datetime
  end
end
