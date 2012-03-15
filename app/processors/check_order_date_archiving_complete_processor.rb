class CheckOrderDateArchivingCompleteProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010

  subscribes_to :check_order_date_archiving_complete, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :update_order_date_archiving_complete
  
  def on_message(message)
    logger.debug "CheckOrderDateArchivingCompleteProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    raise "Parameter 'unit_id' is required" if hash[:unit_id].blank?
    @working_order = Unit.find(hash[:unit_id]).order
    @order_id = @working_order.id

    @messagable_id = @order_id
    @messagable_type = "Order"
    
    incomplete_units = Array.new
    
    @working_order.units.each {|unit|
      # If an order can have both patron and dl-only units (i.e. some units have an intended use of "Digital Collection Building")
      # then we have to remove from consideration those units whose intended use is "Digital Collection Building"
      # and consider all other units. 

      if not unit.unit_status == "canceled"
        if not unit.date_archived
          incomplete_units.push(unit.id)
        end
      end
    }
    
    if incomplete_units.empty?
      # The 'patron' units within the order are complete
      message = ActiveSupport::JSON.encode({ :order_id => @order_id })
      publish :update_order_date_archiving_complete, message
      on_success "All units in order #{@order_id} are archived."
    else  
      # Order incomplete.  List units incomplete units in message
      on_failure "Order #{@order_id} has some units (#{incomplete_units.join(', ')}) that have not been archived."
    end
  end
end
