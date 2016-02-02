class CreateOrderEmail < BaseJob

   def perform(message)
      Job_Log.debug "CreateOrderEmailProcessor received: #{message.to_json}"

      # Validate incoming message.  'internal_dir' is required of all imcoming messages.
      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      raise "Parameter 'delivery_files' is required" if message[:delivery_files].blank?

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      @delivery_files = message[:delivery_files]
      email = OrderMailer.web_delivery(@working_order, @delivery_files)
      @working_order.update_attribute(:email, email.body)
      on_success "An email for web delivery method created for order #{@order_id}"
   end
end
