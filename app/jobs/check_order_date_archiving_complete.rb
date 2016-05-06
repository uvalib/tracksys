class CheckOrderDateArchivingComplete < BaseJob

   def do_workflow(message)

      raise "Parameter 'unit' is required" if message[:unit].blank?
      order = message[:unit]

      incomplete_units = Array.new
      order.units.each do |unit|
         # If an order can have both patron and dl-only units (i.e. some units have an intended use of "Digital Collection Building")
         # then we have to remove from consideration those units whose intended use is "Digital Collection Building"
         # and consider all other units.
         if not unit.unit_status == "canceled"
            if not unit.date_archived
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
         on_failure "Order #{order.id} has some units (#{incomplete_units.join(', ')}) that have not been archived."
      end
   end
end
