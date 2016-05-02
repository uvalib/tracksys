class Invoice < ActiveRecord::Base
   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :order, :counter_cache => true

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :order_id, :presence => true
   validates :order, :presence => {
      :message => "association with this Order is no longer valid because it does not exist."
   }

   delegate :date_order_approved, :date_customer_notified,
      :to => :order, :allow_nil => true, :prefix => true
   delegate :customer, to: :order, prefix: true
   delegate :fee_actual, to: :order, prefix: true

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :permanent_nonpayment, lambda { where("permanent_nonpayment != 0") }

   #------------------------------------------------------------------
   # public class methods
   #------------------------------------------------------------------

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------

   def self.past_due()
      date=30.days.ago
      where("date_fee_paid is NULL").where("date_invoice < ?", date)
   end
   def self.notified_past_due()
      date=30.days.ago
      where("date_fee_paid is NULL").where("date_invoice < ?", date).where("date_second_notice_sent is not NULL")
   end
end

# == Schema Information
#
# Table name: invoices
#
#  id                      :integer          not null, primary key
#  order_id                :integer          default(0), not null
#  date_invoice            :datetime
#  invoice_content         :text(65535)
#  created_at              :datetime
#  updated_at              :datetime
#  invoice_number          :integer
#  fee_amount_paid         :integer
#  date_fee_paid           :datetime
#  date_second_notice_sent :datetime
#  transmittal_number      :text(65535)
#  notes                   :text(65535)
#  invoice_copy            :binary(16777215)
#  permanent_nonpayment    :boolean          default(FALSE)
#
