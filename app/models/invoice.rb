# == Schema Information
#
# Table name: invoices
#
#  id                       :integer         not null, primary key
#  order_id                 :integer
#  date_invoice_sent        :datetime
#  fee_amount_paid          :decimal(, )
#  date_second_invoice_sent :datetime
#  notes                    :text
#  invoice_copy             :binary(2097152)
#  created_at               :datetime
#  updated_at               :datetime
#

require "#{Hydraulics.models_dir}/invoice"

class Invoice
end
