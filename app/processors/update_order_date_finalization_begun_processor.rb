class UpdateOrderDateFinalizationBegunProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :update_order_date_finalization_begun, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :check_unit_delivery_mode

  def on_message(message)
    logger.debug "UpdateOrderDateFinalizationBegunProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    
    @working_unit = Unit.find(hash[:unit_id])
    @working_order = @working_unit.order
    @messagable = @working_order
    @order_id = @working_order.id

    @working_order.date_finalization_begun = Time.now
    @working_order.save!

    on_success "Date Finalization Begun updated for order #{@order_id}"
    message = ActiveSupport::JSON.encode({ :unit_id => hash[:unit_id] })
    publish :check_unit_delivery_mode, message
  end
end
