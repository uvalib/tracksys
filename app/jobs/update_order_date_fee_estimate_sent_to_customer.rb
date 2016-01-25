class UpdateOrderDateFeeEstimateSentToCustomer < BaseJob

   def perform(message)
      Job_Log.debug "UpdateOrderDateFeeEstimateSentToCustomerProcessor received: #{message.to_json}"

      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()
      @working_order.date_fee_estimate_sent_to_customer = Time.now
      @working_order.save!

      UpdateOrderStatusDeferred({:order_id => @order_id})
      on_success "Date fee estiamte sent to customer has been updated."
   end
end
