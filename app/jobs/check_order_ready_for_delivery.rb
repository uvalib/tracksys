class CheckOrderReadyForDelivery < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id] )
   end

   # This processor only accepts units whose delivery_mode = 'patron', so there is no need to worry, from here on out, about 'dl' materials.
   def do_workflow(message)
      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      order = Order.find(message[:order_id])
      incomplete_units = []

      logger.info "Checking units for completeness..."
      order.units.each do |unit|
         # If an order can have both patron and dl-only units (i.e. some units have an intended use of "Digital Collection Building")
         # then we have to remove from consideration those units whose intended use is "Digital Collection Building"
         # and consider all other units.
         logger.info "   Check unit #{unit.id}"
         if  unit.intended_use.description != "Digital Collection Building"
            if unit.unit_status != "canceled"
               if unit.date_patron_deliverables_ready.nil?
                  logger.info "   Unit #{unit.id} incomplete"
                  incomplete_units.push(unit.id)
               else
                  logger.info "   Unit #{unit.id} COMPLETE"
               end
            else
               logger.info "   unit is canceled"
            end
         else
            logger.info "   unit is for digital collection building"
         end
      end
      logger.info "Incomplete units count #{incomplete_units.count}"

      # If any units are not comlete, the order is incomplete
      if !incomplete_units.empty?
         logger.info("Order #{message[:order_id]} is incomplete with units #{incomplete_units.join(", ")} still unfinished")
         return
      end

      # Nothign more to do if customer was already notified...
      if order.date_customer_notified
         log_failure("The date_customer_notified field on order #{message[:order_id]} is filled out.  The order appears to have been delivered already.")
         return
      end

      # The 'patron' units within the order are complete, and customer not yet notified
      # Flag deliverable complete data and begin order QA process that will result
      # in a PDF ad patron email being generated if all is goos
      logger.info("All units in order #{message[:order_id]} are complete and will now begin the delivery process.")
      order.update_attribute(:date_patron_deliverables_complete, Time.now)

      # Failed QA checks will terminiate the job immediately
      qa_order_fees(order)

      # QA was successful, generate PDF and email
      RestClient.post "#{Settings.jobs_url}/orders/#{message[:order_id]}/pdf", nil

      # Email can be created from this job or from UI. For this
      # reason, it remain its own standalone job
      RestClient.post "#{Settings.jobs_url}/orders/#{message[:order_id]}/email", nil
   end


   private
   def qa_order_fees(order)
      logger.info "QA order #{order.id} status and fees..."

      # At this point, the order status must be 'approved'.
      if order.order_status != 'approved'
         fatal_error "Order #{order.id} does not have an order status of 'approved'.  Please correct before proceeding."
      end

      # An order whose customer is non-UVA and whose actual fee is blank is invalid.
      if order.customer.academic_status_id == 1 && order.fee.nil?
         fatal_error "Order #{order.id} has a non-UVA customer and the fee is blank."
      end

      # If there is a value for order fee then there must be a paid invoice
      if !order.fee.nil? && order.fee > 0
         if order.fee_paid? == false
            fatal_error "Error with order fee: Order #{order.id} has an unpaid fee."
         else
            logger.info "Order fee checked; fee paid."
         end
      else
         logger.info "Order fee checked. #{order.id} has no fees associated with it."
      end

      logger.info "Order #{order.id} has passed QA"
   end
end
