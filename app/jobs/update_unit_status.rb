class UpdateUnitStatus < BaseJob

   def perform(message)
      Job_Log.debug "UpdateUnitStatusProcessor received: #{message.to_json}"

      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?
      raise "Parameter 'unit_status is required" if message[:unit_status].blank?
      raise "Parameter 'unit_status' is not a valid value" if Unit::UNIT_STATUSES.include?(message[:unit_status])

      @messagable_id = message[:unit_id]
      @messagable_type = "Unit"
      set_workflow_type()

      @messagable.update_attribute(:unit_status, message[:unit_status])
      on_success "Unit #{message[:unit_id]} status changed to #{message[:unit_status]}."

      # Update Unit's Order to 'approved' if all sibling Units are 'approved' or 'cancelled'
      order = @messagable.order
      if order.ready_to_approve?
         UpdateOrderStatusApproved.exec_now({ :order_id => order.id })
      end
   end
end
