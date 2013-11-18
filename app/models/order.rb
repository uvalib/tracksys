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
  
  # Processor information
  require 'activemessaging/processor'
  include ActiveMessaging::MessageSender

  def approve_order
    message = ActiveSupport::JSON.encode( {:order_id => self.id})
    publish :update_order_status_approved, message
  end

  def cancel_order
    message = ActiveSupport::JSON.encode( {:order_id => self.id} )
    publish :update_order_status_canceled, message
  end

  def check_order_ready_for_delivery
    message = ActiveSupport::JSON.encode( {:order_id => self.id})
    publish :check_order_ready_for_delivery, message
  end

  def create_order_pdf
    message = ActiveSupport::JSON.encode( {:order_id => self.id, :fee => self.fee_actual.to_i})
    publish :create_order_pdf, message
  end

  def qa_order_data
    message = ActiveSupport::JSON.encode({:order_id => self.id})
    publish :qa_order_data, message
  end

  def send_fee_estimate_to_customer(computing_id)
    @user = StaffMember.find_by_computing_id(computing_id) 
    @first_name = @user.first_name
    message = ActiveSupport::JSON.encode( {:order_id => self.id, :first_name => @first_name})
    publish :send_fee_estimate_to_customer, message
  end

  def send_order_email
    message = ActiveSupport::JSON.encode( {:order_id => self.id})
    publish :send_order_email, message
  end  # End processor methods
end
