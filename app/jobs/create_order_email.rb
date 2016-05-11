class CreateOrderEmail < BaseJob

   def do_workflow(message)

      raise "Parameter 'order' is required" if message[:order].blank?
      raise "Parameter 'delivery_files' is required" if message[:delivery_files].blank?

      order = message[:order]
      email = OrderMailer.web_delivery(order, message[:delivery_files] )
      order.update_attribute(:email, email.body)
      on_success "An email for web delivery method created for order #{order_id}"
   end
end
