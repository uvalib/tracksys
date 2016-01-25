require "#{Hydraulics.models_dir}/order"

class Order
   ORDER_STATUSES << "completed"
   include BuildOrderPDF
   serialize :email

   after_update :fix_updated_counters

   scope :from_fine_arts, joins(:agency).where("agencies.name" => "Fine Arts Library")
   scope :not_from_fine_arts, where('agency_id != 37 or agency_id is null')

   def self.due_within(timespan)
      if ! timespan.kind_of?(ActiveSupport::TimeWithZone)
         logger.error "#{self.name}#due_within expecting ActiveSupport::TimeWithZone as argument.  Got #{timespan.class} instead"
         timespan = 1.week.from_now
      end
      if Time.now.to_date == timespan.to_date
         where("date_due = ?", Date.today)
      elsif Time.now > timespan
         where("date_due < ?", Date.today).where("date_due > ?", timespan)
      else
         where("date_due > ?", Date.today).where("date_due < ?", timespan)
      end
   end
   def self.overdue_as_of(date=0.days.ago)
      if ! date.kind_of?(ActiveSupport::TimeWithZone)
         logger.error "#{self.name}#overdue_as_of Expecting ActiveSupport::TimeWithZone as argument. Got #{date.class} instead"
         date=0.days.ago
      end
      where("date_request_submitted > ?", date - 1.years ).where("date_due < ?", date).where("date_deferred is NULL").where("date_canceled is NULL").where("order_status != 'canceled'").where("date_patron_deliverables_complete is NULL").where("order_status != 'deferred'").where("order_status != 'completed'")
   end

   scope :overdue, overdue_as_of(0.days.ago)
   scope :due_today, due_within(0.day.from_now)
   scope :due_in_a_week, due_within(1.week.from_now)
   scope :complete, where("date_archiving_complete is not null OR order_status = 'completed'")

   # Determine if any of an Order's Units are not 'approved' or 'cancelled'
   def ready_to_approve?
      status = self.units.map(&:unit_status) & ['condition', 'copyright', 'unapproved']
      return status.empty?
   end
   
   def title
      if order_title
         order_title
      elsif units.first.respond_to?(:bibl_id?)
         if units.first.bibl_id?
            units.first.bibl.title
         else
            nil
         end
      else
         nil
      end
   end

   def approve_order
      UpdateOrderStatusApproved.exec( {:order_id => self.id})
   end

   def cancel_order
      UpdateOrderStatusCanceled.exec( {:order_id => self.id} )
   end

   def check_order_ready_for_delivery
      CheckOrderReadyForDelivery.exec( {:order_id => self.id})
   end

   def create_order_pdf
      CreateOrderPdf.exec( {:order_id => self.id, :fee => self.fee_actual.to_i})
   end

   def qa_order_data
      QaOrderData.exec({:order_id => self.id})
   end

   def send_fee_estimate_to_customer(computing_id)
      @user = StaffMember.find_by_computing_id(computing_id)
      @first_name = @user.first_name
      SendFeeEstimateToCustomer.exec( {:order_id => self.id, :first_name => @first_name})
   end

   def send_order_email
      SendOrderEmail.exec({:order_id => self.id})
   end
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
