class CheckOrderDeliveryMethod < BaseJob

   def perform(message)
      Job_Log.debug "CheckOrderDeliveryMethodProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      on_success "Order #{@order_id} has the default delivery method of 'web delivery'"
      CreateOrderZip.exec_now({:order_id => @order_id})
   end
end
