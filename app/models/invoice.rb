require "#{Hydraulics.models_dir}/invoice"

class Invoice
  def self.outstanding_as_of(date=0.days.ago)
    if ! date.kind_of?(ActiveSupport::TimeWithZone)
      logger.error "#{self.name}#outstanding_as_of Expecting ActiveSupport::TimeWithZone as argument. Got #{date.class} instead"
      date=0.days.ago
    end
    where("date_fee_paid is NULL").where("date_invoice < ?", date)
  end
  def self.second_notice_as_of(date=0.days.ago)
    if ! date.kind_of?(ActiveSupport::TimeWithZone)
      logger.error "#{self.name}#second_notice_as_of Expecting ActiveSupport::TimeWithZone as argument. Got #{date.class} instead"
      date=0.days.ago
    end
    where("date_fee_paid is NULL").where("date_invoice < ?", date).where("date_second_notice_sent is not NULL")
  end

  scope :past_due, outstanding_as_of(30.days.ago)
  scope :notified_past_due, second_notice_as_of(30.days.ago)
  scope :permanent_nonpayment, lambda { where("permanent_nonpayment != 0") } 

  delegate :customer, to: :order, prefix: true
  delegate :fee_actual, to: :order, prefix: true
end
# == Schema Information
#
# Table name: invoices
#
#  id                      :integer(4)      not null, primary key
#  order_id                :integer(4)      default(0), not null
#  date_invoice            :datetime
#  invoice_content         :text
#  created_at              :datetime
#  updated_at              :datetime
#  invoice_number          :integer(4)
#  fee_amount_paid         :integer(4)
#  date_fee_paid           :datetime
#  date_second_notice_sent :datetime
#  transmittal_number      :text
#  notes                   :text
#  invoice_copy            :binary(16777215
#  permanent_nonpayment    :boolean(1)      default(FALSE)
#

