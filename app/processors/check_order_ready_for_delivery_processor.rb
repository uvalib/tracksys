class CheckOrderReadyForDeliveryProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  # This processor only accepts units whose delivery_mode = 'patron', so there is no need to worry, from here on out, about 'dl' materials.

  subscribes_to :check_order_ready_for_delivery, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_order_date_patron_deliverables_complete
  
  def on_message(message)
    logger.debug "CheckOrderCompleteCheckProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'order_id' is required" if hash[:order_id].blank?
    
    @working_order = Order.find(hash[:order_id])
    @order_id = @working_order.id
    incomplete_units = Array.new

    @working_order.units.each {|unit|
      # If an order can have both patron and dl-only units (i.e. some units have an intended use of "Digital Collection Building")
      # then we have to remove from consideration those units whose intended use is "Digital Collection Building"
      # and consider all other units. 
      if not unit.intended_use.description == "Digital Collection Building"
        if not unit.unit_status == "canceled"
          if unit.date_patron_deliverables_ready.nil?  
            incomplete_units.push(unit.id)
          end
        end
      end
    }

    if incomplete_units.empty?
      if @working_order.date_customer_notified
        # The order appears to have been delivered to the customer already
        on_failure("The date_customer_notified field on order #{@working_order.id} is filled out.  The order appears to have been delivered already.")
      else
        # The 'patron' units within the order are complete
        message = ActiveSupport::JSON.encode({ :order_id => @order_id })
        publish :update_order_date_patron_deliverables_complete, message
        on_success("All units in order #{@order_id} are complete and will now begin the delivery process.")
      end
    else  
      # Order incomplete.  List units incomplete units in message
      on_success("Order #{@order_id} is incomplete with units #{incomplete_units.join(", ")} still unfinished")
    end
  end
end
