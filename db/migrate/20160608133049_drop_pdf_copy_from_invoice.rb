class DropPdfCopyFromInvoice < ActiveRecord::Migration
  def change
     remove_column :invoices, :invoice_copy, :binary, :limit => 10.megabyte
     remove_column :invoices, :invoice_content, :text
  end
end
