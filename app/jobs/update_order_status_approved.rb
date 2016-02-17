class UpdateOrderStatusApproved < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)

      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      order = Order.find(message[:order_id])
      order.order_status = 'approved'
      order.date_order_approved = Time.now
      order.save!

      on_success "The order status has been changed to approved and the date approved has been updated."
   end
end
