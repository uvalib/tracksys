class CreateOrderEmail < BaseJob

   def perform(message)
      Job_Log.debug "CreateOrderEmailProcessor received: #{message.to_json}"

      # Validate incoming message.  'internal_dir' is required of all imcoming messages.
      raise "Parameter 'order_id' is required" if message[:order_id].blank?
      if message[:dvd_delivery_location_id].blank? and message[:delivery_files].blank?
         raise "Either parameter 'dvd_delivery_location_id' or 'delivery_files' is required"
      end

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable_id = message[:order_id]
      @messagable_type = "Order"
      set_workflow_type()

      # Messages coming into this sytem either have message[:delivery_files] or message[:dvd_deliery_locaiton]
      # based on whether the order will be delivered via DVD or web

      if message[:dvd_delivery_location_id]
         @dvd_delivery_location = DvdDeliveryLocation.find(message[:dvd_delivery_location_id])
         email = OrderMailer.dvd_delivery(@working_order, @dvd_delivery_location)
         @working_order.update_attribute(:email, email.body)
         on_success "An email for DVD delivery method created for order #{@order_id}"
      elsif message[:delivery_files]
         @delivery_files = message[:delivery_files]
         email = OrderMailer.web_delivery(@working_order, @delivery_files)
         @working_order.update_attribute(:email, email.body)
         on_success "An email for web delivery method created for order #{@order_id}"
      else
      end
   end
end
