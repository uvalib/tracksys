class UpdateOrderStatusDeferredProcessor < ApplicationProcessor

  subscribes_to :update_order_status_deferred, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)  
    logger.debug "UpdateOrderStatusDeferredProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"

    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @working_order.order_status = 'deferred'
    @working_order.save! 

    on_success "The order has been deferred."        
  end
end
