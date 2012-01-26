class SendOrderEmailProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :send_order_email, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_order_date_customer_notified
  
  def on_message(message)
    logger.debug "SendOrderEmailProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @email = @working_order.email

    # send email
    DeliveryMailer.deliver(@email)

    # send message
    message = ActiveSupport::JSON.encode({:order_id => @order_id})
    publish :update_order_date_customer_notified, message
    on_success("Email sent to #{@first_name} #{@last_name} (#{@email}) for Order #{@order_id}.")
  end
end
