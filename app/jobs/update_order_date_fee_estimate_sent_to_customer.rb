class UpdateOrderDateFeeEstimateSentToCustomer < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)

      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @working_order.date_fee_estimate_sent_to_customer = Time.now
      @working_order.order_status = 'deferred'
      @working_order.save!

      on_success "Date fee estiamte sent to customer has been updated."
   end
end
