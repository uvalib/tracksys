class UpdateOrderDateArchivingComplete < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)

      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @working_order.date_archiving_complete = Time.now
      @working_order.save!
      on_success "Order #{@order_id} has been fully archived."
   end
end
