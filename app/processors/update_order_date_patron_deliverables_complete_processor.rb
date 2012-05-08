class UpdateOrderDatePatronDeliverablesCompleteProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :update_order_date_patron_deliverables_complete, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :qa_order_data

  def on_message(message)
    logger.debug "UpdateOrderDatePatronDeliverablesCompleteProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys
    
    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    @working_order.date_patron_deliverables_complete = Time.now
    @working_order.save!

    message = ActiveSupport::JSON.encode({ :order_id => @order_id })
    publish :qa_order_data, message
    on_success "All patron deliverables of order #{@order_id} have been created."
  end 
end
