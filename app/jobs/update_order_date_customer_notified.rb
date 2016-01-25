class UpdateOrderDateCustomerNotified < BaseJob

   def perform(message)
      Job_Log.debug "UpdateOrderDateCustomerNotifiedProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      # Update date_completed attribute
      @working_order.date_customer_notified = Time.now
      @working_order.save!
      on_success "The customer of order #{@order_id} has been notified."

      CreateInvoice.exec_now({:order_id => @order_id})
   end
end
