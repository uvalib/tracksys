class QaOrderData < BaseJob

   def do_workflow(message)

      # Validate incoming message
      raise "Parameter 'order' is required" if message[:order].blank?
      order = message[:order]

      # Create error message holder array
      failure_messages = Array.new

      #-------------------------
      # QA Logic
      #-------------------------

      # At this point, the order status must be 'approved'.
      if not order.order_status == 'approved'
         failure_messages << "Order #{order.id} does not have an order status of 'approved'.  Please correct before proceeding."
      end

      # An order whose customer is non-UVA and whose actual fee is blank is invalid.  Only if actual_fee has a value is the order valid.
      if order.customer.academic_status_id == 1 and order.fee_actual.nil?
         failure_messages << "Order #{order.id} has a non-UVA customer and the 'Actual Fee' is blank.  Please fill in with a value."
      end

      #-------------------------
      # Failure Message Handling
      #-------------------------

      if failure_messages.empty?
         on_success "Order #{order.id} has passed the Qa Order Data Processor."
         CheckOrderFee.exec_now({ :order => order }, self)
      else
         failure_messages.each do |message|
            on_failure message
            if message == failure_messages.last
               on_error "Order #{order.id} has failed the QA Order Data Processor"
            end
         end
      end
   end
end
