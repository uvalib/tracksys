class UpdateOrderEmailDateProcessor < ApplicationProcessor

  subscribes_to :update_order_email_date, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :send_order_email
  
  def on_message(message)  
    logger.debug "UpdateOrderEmailDateProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @working_order.email.date=Time.now
    @working_order.save!  
 
    message = ActiveSupport::JSON.encode({:order_id => @order_id})
    publish :send_order_email, message
    on_success "The date field in the order email has been updated to now."        
  end
end
