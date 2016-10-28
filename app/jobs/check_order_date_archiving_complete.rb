class CheckOrderDateArchivingComplete < BaseJob

   def do_workflow(message)

      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      order = Order.find(message[:order_id])

      incomplete_units = Array.new
      order.units.each do |unit|
         # If an order can have both patron and dl-only units (i.e. some units have an intended use of "Digital Collection Building")
         # then we have to remove from consideration those units whose intended use is "Digital Collection Building"
         # and consider all other units.
         if unit.unit_status != "canceled"
            if unit.date_archived.blank?
               incomplete_units.push(unit.id)
            end
         end
      end

      if incomplete_units.empty?
         # The 'patron' units within the order are complete
         order.update_attribute(:date_archiving_complete, Time.now)
         on_success "All units in order #{order.id} are archived."
      else
         # Order incomplete.  List units incomplete units in message
         logger.info "Order #{order.id} has some units (#{incomplete_units.join(', ')}) that have not been archived."
      end
   end
end
