class UpdateOrderStatusApprovedProcessor < ApplicationProcessor

  subscribes_to :update_order_status_approved, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "UpdateOrderStatusApprovedProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @working_order.order_status = 'approved'
    @working_order.date_order_approved = Time.now
    @working_order.save!

    on_success "The order status has been changed to approved and the data approved has been updated."        
  end
end
