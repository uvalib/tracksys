require "#{Hydraulics.models_dir}/order"

class Order
  serialize :email

  after_update :fix_updated_counters

  scope :from_fine_arts, joins(:agency).where("agencies.name" => "Fine Arts Library")
  scope :not_from_fine_arts, where('agency_id != 37 or agency_id is null')

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
