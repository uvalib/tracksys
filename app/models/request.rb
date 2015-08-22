require "#{Hydraulics.models_dir}/request"

class Request
  belongs_to :customer, :inverse_of => :requests

  accepts_nested_attributes_for :units
  accepts_nested_attributes_for :customer

  validates :units, :presence => {
    :message => 'are required.  Please add at least one item to your request.'
  }

  validates_presence_of :customer
end
# == Schema Information
#
# Table name: orders
#
#  id                                 :integer(4)      not null, primary key
#  customer_id                        :integer(4)      default(0), not null
#  agency_id                          :integer(4)
#  order_status                       :string(255)
#  is_approved                        :boolean(1)      default(FALSE), not null
#  order_title                        :string(255)
#  date_request_submitted             :datetime
#  date_order_approved                :datetime
#  date_deferred                      :datetime
#  date_canceled                      :datetime
#  date_permissions_given             :datetime
#  date_started                       :datetime
#  date_due                           :date
#  date_customer_notified             :datetime
#  fee_estimated                      :decimal(7, 2)
#  fee_actual                         :decimal(7, 2)
#  entered_by                         :string(255)
#  special_instructions               :text
#  created_at                         :datetime
#  updated_at                         :datetime
#  staff_notes                        :text
#  dvd_delivery_location_id           :integer(4)
#  email                              :text
#  date_patron_deliverables_complete  :datetime
#  date_archiving_complete            :datetime
#  date_finalization_begun            :datetime
#  date_fee_estimate_sent_to_customer :datetime
#  units_count                        :integer(4)      default(0)
#  automation_messages_count          :integer(4)      default(0)
#  invoices_count                     :integer(4)      default(0)
#  master_files_count                 :integer(4)      default(0)
#

