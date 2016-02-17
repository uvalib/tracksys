class SendOrderEmail < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order_id])
   end

   def do_workflow(message)
      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @email = @working_order.email

      # recreate the email but there is no longer a need to pass correct
      # information because the body will be drawn from order.email
      new_email = OrderMailer.web_delivery(@working_order, ['holding'])
      new_email.body = @email.to_s
      new_email.date = Time.now
      new_email.deliver

      UpdateOrderDateCustomerNotified.exec_now({:order_id => @order_id}, self)
      on_success("Email sent to #{@first_name} #{@last_name} (#{@email}) for Order #{@order_id}.")
   end
end
