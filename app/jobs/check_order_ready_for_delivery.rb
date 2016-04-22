class CheckOrderReadyForDelivery < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id])
   end

   # This processor only accepts units whose delivery_mode = 'patron', so there is no need to worry, from here on out, about 'dl' materials.
   def do_workflow(message)
      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      @working_order = Order.find(message[:order_id])
      incomplete_units = Array.new

      @working_order.units.each do |unit|
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
      end

      if incomplete_units.empty?
         if @working_order.date_customer_notified
            # The order appears to have been delivered to the customer already
            on_failure("The date_customer_notified field on order #{message[:order_id]} is filled out.  The order appears to have been delivered already.")
         else
            # The 'patron' units within the order are complete
            on_success("All units in order #{message[:order_id]} are complete and will now begin the delivery process.")
            @working_order.update_attribute(:date_patron_deliverables_complete, Time.now)
            QaOrderData.exec_now({ :order_id => @working_order.id }, self)
         end
      else
         # Order incomplete.  List units incomplete units in message
         on_success("Order #{message[:order_id]} is incomplete with units #{incomplete_units.join(", ")} still unfinished")
      end
   end
end
