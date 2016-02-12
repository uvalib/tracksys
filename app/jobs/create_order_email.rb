class CreateOrderEmail < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=>"Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)

      # Validate incoming message.  'internal_dir' is required of all imcoming messages.
      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      raise "Parameter 'delivery_files' is required" if message[:delivery_files].blank?

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)

      @delivery_files = message[:delivery_files]
      email = OrderMailer.web_delivery(@working_order, @delivery_files)
      @working_order.update_attribute(:email, email.body)
      on_success "An email for web delivery method created for order #{@order_id}"
   end
end
