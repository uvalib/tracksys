class UpdateOrderDateCustomerNotifiedProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :update_order_date_customer_notified, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_invoice
  
  def on_message(message)
    logger.debug "UpdateOrderDateCustomerNotifiedProcessor received: " + message

    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    
    # Update date_completed attribute
    @working_order.date_customer_notified = Time.now
    @working_order.save!
    on_success "The customer of order #{@order_id} has been notified."

    message = ActiveSupport::JSON.encode({:order_id => @order_id})
    publish :create_invoice, message
  end
end
