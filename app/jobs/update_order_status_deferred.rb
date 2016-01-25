class UpdateOrderStatusDeferred < BaseJob

   def perform(message)
      Job_Log.debug "UpdateOrderStatusDeferredProcessor received: #{messageto_json}"

      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      set_workflow_type()
      @messagable_id = message[:order_id]
      @messagable_type = "Order"

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @working_order.update_attribute(:order_status, 'deferred')

      on_success "The order has been deferred."
   end
end
