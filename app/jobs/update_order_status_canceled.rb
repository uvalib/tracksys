class UpdateOrderStatusCanceled < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)

      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      order = Order.find(message[:order_id])
      order.order_status = 'canceled'
      order.date_canceled = Time.now
      order.save!
      
      on_success "The order status has been changed to canceled and the date cancelled has been updated."
   end
end
