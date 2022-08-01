class Invoice < ApplicationRecord
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
   delegate :fee, to: :order, prefix: true

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
   def self.declined()
      where("date_fee_declined is not null")
   end
   def self.past_due()
      date=30.days.ago
      where("date_fee_paid is NULL").where("date_invoice < ?", date)
         .where("date_fee_declined is null")
         .joins(:order).where("orders.fee is not null and orders.fee > 0")
   end
   def self.notified_past_due()
      date=30.days.ago
      where("date_fee_paid is NULL").where("date_invoice < ?", date).where("date_second_notice_sent is not NULL")
         .where("date_fee_declined is null")
         .joins(:order).where("orders.fee is not null and orders.fee > 0")
   end
end

# == Schema Information
#
# Table name: invoices
#
#  id                      :integer          not null, primary key
#  order_id                :integer          default(0), not null
#  date_invoice            :datetime
#  created_at              :datetime
#  updated_at              :datetime
#  fee_amount_paid         :integer
#  date_fee_paid           :datetime
#  date_second_notice_sent :datetime
#  transmittal_number      :text(65535)
#  notes                   :text(65535)
#  permanent_nonpayment    :boolean          default(FALSE)
#  date_fee_declined       :datetime
#
