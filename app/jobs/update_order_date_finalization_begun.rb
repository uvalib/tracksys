class UpdateOrderDateFinalizationBegun < BaseJob
   def perform(message)
      Job_Log.debug "UpdateOrderDateFinalizationBegunProcessor received: #{message.to_json}"

      # Validate incoming message
      raise "Parameter 'unit_id' is required" if message[:unit_id].blank?

      @working_unit = Unit.find(message[:unit_id])
      @working_order = @working_unit.order
      @order_id = @working_order.id
      @messagable_id = @order_id
      @messagable_type = "Order"
      set_workflow_type()
      @working_order.date_finalization_begun = Time.now
      @working_order.save!

      on_success "Date Finalization Begun updated for order #{@order_id}"
      CheckUnitDeliveryMode.exec_now({ :unit_id => message[:unit_id] })
   end
end
