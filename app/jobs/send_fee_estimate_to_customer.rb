class SendFeeEstimateToCustomer < BaseJob
   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)

      raise "Parameter 'order_id' is required" if message[:order_id].blank?

      order = Order.find( message[:order_id] )
      OrderMailer.send_fee_estimate(order).deliver
      logger().info "Fee estimate email sent to customer."

      order.update_attribute(:date_fee_estimate_sent_to_customer, Time.now)
      logger().info "Date fee estimate sent to customer has been updated."

      order.update_attribute(:order_status, 'deferred')
      logger().info "The order has been deferred."
   end
end
