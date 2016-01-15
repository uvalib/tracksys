class CheckOrderDeliveryMethod < BaseJob

   def perform(message)
      Job_Log.debug "CheckOrderDeliveryMethodProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      if @working_order.dvd_delivery_location
         # Send message with the order and id of the dvd_delivery_location
         on_success "Order #{@order_id} has a delivery method of 'data DVD'"
         CreateOrderEmail.exec_now({:order_id => @order_id, :dvd_delivery_location_id => @working_order.dvd_delivery_location_id})
      else
         on_success "Order #{@order_id} has the default delivery method of 'web delivery'"
         CreateOrderZip.exec_now({:order_id => @order_id})
      end
   end
end
