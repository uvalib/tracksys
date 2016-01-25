class SendFeeEstimateToCustomer < BaseJob
   def perform(message)
      Job_Log.debug "SendFeeEstimateToCustomerProcessor received: #{message.to_json}"

      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      @order_id = message[:order_id]
      @first_name = message[:first_name]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()
      OrderMailer.send_fee_estimate(@working_order).deliver

      UpdateOrderDateFeeEstimateSentToCustomer.exec_now({:order_id => @order_id})
      on_success "Fee estimate email sent to customer."
   end
end
