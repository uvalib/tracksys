class UpdateOrderStatusCanceledProcessor < ApplicationProcessor

  subscribes_to :update_order_status_canceled, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "UpdateOrderStatusCanceledProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable = @working_order
    @working_order.order_status = 'canceled'
    @working_order.date_canceled = Time.now
    @working_order.save!

    on_success "The order has been marked as cancelled and the date cancelled has been updated."
  end
end
