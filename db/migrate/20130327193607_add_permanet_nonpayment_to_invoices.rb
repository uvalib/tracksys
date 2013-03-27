class AddPermanetNonpaymentToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :permanent_nonpayment, :boolean, :default => false
  end
end
