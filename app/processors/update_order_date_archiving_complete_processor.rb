class UpdateOrderDateArchivingCompleteProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :update_order_date_archiving_complete, {:ack=>'client', 'activemq.prefetchSize' => 1}

  def on_message(message)
    logger.debug "UpdateOrderDateArchivingCompleteProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    
    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable = @working_order

    @working_order.date_archiving_complete = Time.now
    @working_order.save!
    on_success "Order #{@order_id} has been fully archived."
  end
end
