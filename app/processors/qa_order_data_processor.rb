class QaOrderDataProcessor < ApplicationProcessor

# Written by: Andrew Curley (aec6v@virginia.edu) and Greg Murray (gpm2a@virginia.edu)
# Written: January - March 2010
  
  subscribes_to :qa_order_data, {:ack=>'client', 'activemq.prefetchSize' => 1}
  publishes_to :check_order_fee
    
  def on_message(message)
    logger.debug "QAOrderDataProcessor received: " + message
    
    # decode JSON message into Ruby hash
    hash = ActiveSupport::JSON.decode(message).symbolize_keys

    # Validate incoming message
    raise "Parameter 'order_id' is required" if hash[:order_id].blank?    

    @order_id = hash[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = hash[:order_id]
    @messagable_type = "Order"
    @workflow_type = AutomationMessage::WORKFLOW_TYPES_HASH.fetch(self.class.name.demodulize)

    # Create error message holder array
    failure_messages = Array.new

    #-------------------------
    # QA Logic
    #-------------------------

    # At this point, the order status must be 'approved'.
    if not @working_order.order_status == 'approved'
      failure_messages << "Order #{@order_id} does not have an order status of 'approved'.  Please correct before proceeding."
    end
     
    # An order whose customer is non-UVA and whose actual fee is blank is invalid.  Only if actual_fee has a value is the order valid.
    if @working_order.customer.academic_status_id == 1 and @working_order.fee_actual.nil?
      failure_messages << "Order #{@order_id} has a non-UVA customer and the 'Actual Fee' is blank.  Please fill in with a value."
    end

    #-------------------------
    # Failure Message Handling
    #-------------------------

    if failure_messages.empty?
      on_success "Order #{@order_id} has passed the Qa Order Data Processor."
      message = ActiveSupport::JSON.encode({ :order_id => @order_id })
      publish :check_order_fee, message
    else
      failure_messages.each {|message|
        on_failure message
        if message == failure_messages.last
          on_error "Order #{@order_id} has failed the QA Order Data Processor"
        end
      }
    end   
  end
end
