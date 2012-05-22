class CreateOrderEmailProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :create_order_email, {:ack=>'client', 'activemq.prefetchSize' => 1}
  
  def on_message(message)
    logger.debug "CreateOrderEmailProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message.  'internal_dir' is required of all imcoming messages.
    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    if hash[:dvd_delivery_location_id].blank? and hash[:delivery_files].blank?
      raise "Either parameter 'dvd_delivery_location_id' or 'delivery_files' is required"
    end

    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    # Messages coming into this sytem either have hash[:delivery_files] or hash[:dvd_deliery_locaiton]
    # based on whether the order will be delivered via DVD or web

    if hash[:dvd_delivery_location_id]
      @dvd_delivery_location = DvdDeliveryLocation.find(hash[:dvd_delivery_location_id])
      email = OrderMailer.dvd_delivery(@working_order, @dvd_delivery_location)
      @working_order.update_attribute(:email, email.body)
      on_success "An email for DVD delivery method created for order #{@order_id}"
    elsif hash[:delivery_files]
      @delivery_files = hash[:delivery_files]
      email = OrderMailer.web_delivery(@working_order, @delivery_files)
      @working_order.update_attribute(:email, email.body)
      on_success "An email for web delivery method created for order #{@order_id}"
    else
    end
  end
end
