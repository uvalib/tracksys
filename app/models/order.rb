require "#{Hydraulics.models_dir}/order"

class Order
  after_update :fix_updated_counters

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

  def send_order_email
    message = ActiveSupport::JSON.encode( {:order_id => params[:id]})
    publish :update_order_email_date, message
  end

  # def check_order_ready_for_delivery
  #   message = ActiveSupport::JSON.encode( {:order_id => self.id})
  #   publish :check_order_ready_for_delivery, message
  #   flash[:notice] = "Workflow started at checking the completeness of the order."
  #   redirect_to admin_order_path
  # end

  # def send_fee_estimate_to_customer
  #   if RAILS_ENV == 'test' or RAILS_ENV == 'development'
  #     computing_id = 'localhost'
  #   else
  #     computing_id = request.env['HTTP_REMOTE_USER'].to_s
  #   end
  #   @user = StaffMember.find_by_computing_id(computing_id) 
  #   @first_name = @user.first_name
  #   message = ActiveSupport::JSON.encode( {:order_id => params[:order_id], :first_name => @first_name})
  #   publish :send_fee_estimate_to_customer, message
  #   flash[:notice] = "Fee estimate sent to customer."
  #   redirect_to :action => "show", :id => params[:order_id]
  # end


end
