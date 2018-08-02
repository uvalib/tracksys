class SendFeeEstimateToCustomer < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id] )
   end

   def do_workflow(message)
      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      order = Order.find(message[:order_id])
      OrderMailer.send_fee_estimate(order).deliver
      logger().info "Fee estimate email sent to customer."

      # If an invoice does not yet exist for this order, create one
      if order.invoices.count == 0
         invoice = Invoice.new
         invoice.order = order
         invoice.date_invoice = Time.now
         invoice.save!
         logger.info "A new invoice has been created for order #{order.id}."
      else
         logger.info "An invoice already exists for order #{order.id}; not creating another."
      end

      if order.order_status != "await_fee"
         order.update(date_fee_estimate_sent_to_customer: Time.now, order_status: 'await_fee')
      end
      logger().info "Order status and date fee estimate sent to customer have been updated."
   end
end
