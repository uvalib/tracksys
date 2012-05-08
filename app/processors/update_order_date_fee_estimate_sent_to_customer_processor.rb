class UpdateOrderDateFeeEstimateSentToCustomerProcessor < ApplicationProcessor

  subscribes_to :update_order_date_fee_estimate_sent_to_customer, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_order_status_deferred
  
  def on_message(message)  
    logger.debug "UpdateOrderDateFeeEstimateSentToCustomerProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)
    @working_order.date_fee_estimate_sent_to_customer = Time.now
    @working_order.save!

    message = ActiveSupport::JSON.encode({:order_id => @order_id})
    publish :update_order_status_deferred, message
    on_success "Date fee estiamte sent to customer has been updated."        
  end
end
