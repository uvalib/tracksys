class CheckOrderFeeProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :check_order_fee, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :create_order_pdf  

  def on_message(message)
    logger.debug "CheckOrderFeeProcessor received: " + message

    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Set unit variables
    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"

    # If there is a value for 'fee_estimated' then there must be a value in 'fee_actual'.
    # If there is no value for 'fee_estimated', the workfow sould proceed.

    if @working_order.fee_estimated and not @working_order.fee_actual
      on_error "Error with order fee: Order #{@order_id} has an estimated fee but no actual fee."
    elsif @working_order.fee_actual and not @working_order.fee_estimated
      on_error "Error with order fee: Check if customer approved fees because the estimated fee is blank while the actual fee is not."
    elsif @working_order.fee_estimated and @working_order.fee_actual
      if @working_order.fee_estimated.to_i.eql?(0) and not @working_order.fee_actual.to_i.eql?(0)
        on_error "Error with order fee: Fee estimated is equal to 0.00 but the fee actual is greater than that.  Check customer correspondence and update information."
      elsif @working_order.fee_estimated.to_i.eql?(0) and @working_order.fee_actual.to_i.eql?(0)
        message = ActiveSupport::JSON.encode({ :order_id => @order_id, :fee => "none" })
        publish :create_order_pdf, message
        on_success "Order fee checked.  #{@order_id} has no fees associated with it."     
      else
        fee = @working_order.fee_actual
        message = ActiveSupport::JSON.encode({ :order_id => @order_id, :fee => fee })
        publish :create_order_pdf, message  
        on_success "Order fee checked. #{@order_id} has a fee of #{fee.to_i} and both the estimated and actual fee values are greater than 0.00"
      end
    else
      message = ActiveSupport::JSON.encode({ :order_id => @order_id, :fee => "none" })
      publish :create_order_pdf, message
      on_success "Order fee checked. #{@order_id} has no fees associated with it."     
    end
  end
end
