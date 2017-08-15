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

      if incomplete_units.empty?
         if order.date_customer_notified
            # The order appears to have been delivered to the customer already
            on_failure("The date_customer_notified field on order #{message[:order_id]} is filled out.  The order appears to have been delivered already.")
         else
            # The 'patron' units within the order are complete
            on_success("All units in order #{message[:order_id]} are complete and will now begin the delivery process.")
            order.update_attribute(:date_patron_deliverables_complete, Time.now)
            QaOrderData.exec_now({ :order => order }, self)
         end
      else
         # Order incomplete.  List units incomplete units in message
         on_success("Order #{message[:order_id]} is incomplete with units #{incomplete_units.join(", ")} still unfinished")
      end
   end
end
