class UpdateOrderDateCustomerNotified < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)
      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @working_order.date_customer_notified = Time.now
      @working_order.save!
      on_success "The customer of order #{@order_id} has been notified."

      CreateInvoice.exec_now({:order_id => @order_id}, self)
   end
end
