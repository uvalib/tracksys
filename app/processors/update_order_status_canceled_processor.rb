class UpdateOrderStatusCanceledProcessor < ApplicationProcessor

  subscribes_to :update_order_status_canceled, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "UpdateOrderStatusCanceledProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?

    @workflow_type = 'patron'
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"

    @working_order = Order.find(hash[:order_id])
    @working_order.order_status = 'canceled'
    @working_order.date_canceled = Time.now
    @working_order.save!

    on_success "The order status has been changed to canceled and the date cancelled has been updated."
  end
end
