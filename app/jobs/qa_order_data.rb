class QaOrderData < BaseJob

  def perform(message)
    Job_Log.debug "QAOrderDataProcessor received: #{message.to_json}"

    # Validate incoming message
    raise "Parameter 'order_id' is required" if message[:order_id].blank?

    @order_id = message[:order_id]
    @working_order = Order.find(@order_id)
    @messagable_id = message[:order_id]
    @messagable_type = "Order"
    set_workflow_type()

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
      CheckOrderFee({ :order_id => @order_id })
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
