class SendOrderEmail < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id] )
   end

   def do_workflow(message)
      order = Order.find(message[:order_id])
      email = order.email
      user = message[:user]

      # recreate the email but there is no longer a need to pass correct
      # information because the body will be drawn from order.email
      new_email = OrderMailer.web_delivery(order, ['holding'])
      new_email.body = email.to_s
      new_email.date = Time.now
      new_email.deliver

      order.update(date_customer_notified: Time.now)
      logger.info("Email sent to #{order.customer.email} (#{email}) for Order #{order.id}.")

      if order.order_status != "completed"
         if !order.complete_order(user)
            logger.info("Marking order COMPLETE")
            log_failure("Order is not complete: #{order.errors.full_messages.to_sentence}")
         else
            logger.info "Order is now complete"
         end
      end
   end
end
