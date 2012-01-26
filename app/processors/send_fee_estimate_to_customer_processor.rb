class SendFeeEstimateToCustomerProcessor < ApplicationProcessor

  subscribes_to :send_fee_estimate_to_customer, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_order_date_fee_estimate_sent_to_customer
  
  def on_message(message)  
    logger.debug "SendFeeEstimateToCustomerProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?

    @order_id = hash[:order_id]
    @first_name = hash[:first_name]
    @working_order = Order.find(@order_id)
    email = OrderMailer.create_send_fee_estimate_to_customer(@working_order, @first_name)
    email.set_content_type("text/html")
    OrderMailer.deliver(email)

    message = ActiveSupport::JSON.encode({:order_id => @order_id})
    publish :update_order_date_fee_estimate_sent_to_customer, message
    on_success "Fee estimate email sent to customer."        
  end
end
