class CheckOrderDeliveryMethodProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :check_order_delivery_method, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_order_zip
  publishes_to :create_order_email
  
  def on_message(message)
    logger.debug "CheckOrderDeliveryMethodProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable = @working_order

    if @working_order.has_delivery_method?("web delivery")
      on_success "Order #{@order_id} has a delivery method of 'web delivery'"
      message = ActiveSupport::JSON.encode({:order_id => @order_id})
      publish :create_order_zip, message
    elsif @working_order.has_delivery_method?("data DVD")
      # Send message with the order and id of the dvd_delivery_location
      on_success "Order #{@order_id} has a delivery method of 'data DVD'"
      message = ActiveSupport::JSON.encode({:order_id => @order_id, :dvd_delivery_location_id => @working_order.dvd_delivery_location_id})
      publish :create_order_email, message
    else
      on_error("#{@order_id} has a non-standard delivery method.  Please investigate!")
    end
  end
end
