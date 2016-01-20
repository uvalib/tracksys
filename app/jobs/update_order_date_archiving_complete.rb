class UpdateOrderDateArchivingComplete < BaseJob

   def perform(message)
      Job_Log.debug "UpdateOrderDateArchivingCompleteProcessor received: #{message.to_json}"

      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()
      @working_order.date_archiving_complete = Time.now
      @working_order.save!
      on_success "Order #{@order_id} has been fully archived."
   end
end
