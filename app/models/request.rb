# == Schema Information
#
# Table name: orders
#
#  id                                 :integer         not null, primary key
#  agency_id                          :integer
#  customer_id                        :integer         default(0), not null
#  dvd_delivery_location_id           :integer
#  units_count                        :integer         default(0)
#  invoices_count                     :integer         default(0)
#  automation_messages_count          :integer         default(0)
#  date_canceled                      :datetime
#  date_deferred                      :datetime
#  date_due                           :date
#  date_fee_estimate_sent_to_customer :datetime
#  date_order_approved                :datetime
#  date_permissions_given             :datetime
#  date_started                       :datetime
#  date_request_submitted             :datetime
#  entered_by                         :string(255)
#  fee_actual                         :decimal(7, 2)
#  fee_estimated                      :decimal(7, 2)
#  is_approved                        :boolean         default(FALSE), not null
#  order_status                       :string(255)
#  order_title                        :string(255)
#  special_instructions               :text
#  staff_notes                        :text
#  date_archiving_complete            :datetime
#  date_customer_notified             :datetime
#  date_finalization_begun            :datetime
#  date_patron_deliverables_complete  :datetime
#  email                              :text
#  created_at                         :datetime
#  updated_at                         :datetime
#

require "#{Hydraulics.models_dir}/request"

class Request
end
