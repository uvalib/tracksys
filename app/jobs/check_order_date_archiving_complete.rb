class CheckOrderDateArchivingComplete < BaseJob

   def perform(message)
      Job_Log.debug "CheckOrderDateArchivingCompleteProcessor received: #{message.to_json}"

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      @working_order = Unit.find(message[:unit_id]).order
      @order_id = @working_order.id
      set_workflow_type()
      @messagable_id = @order_id
      @messagable_type = "Order"

      incomplete_units = Array.new

      @working_order.units.each do |unit|
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
         UpdateOrderDateArchivingComplete.exec_now({ :order_id => @order_id })
         on_success "All units in order #{@order_id} are archived."
      else
         # Order incomplete.  List units incomplete units in message
         on_failure "Order #{@order_id} has some units (#{incomplete_units.join(', ')}) that have not been archived."
      end
   end
end
