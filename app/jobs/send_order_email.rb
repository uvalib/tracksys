class SendOrderEmail < BaseJob

   def perform(message)
      Job_Log.debug "SendOrderEmailProcessor received: #{message.to_json}"

      @order_id = message[:order_id]
      @working_order = Order.find(@order_id)
      @messagable = @working_order
      set_workflow_type()
      @email = @working_order.email

      # recreate the email but there is no longer a need to pass correct
      # information because the body will be drawn from order.email
      new_email = OrderMailer.web_delivery(@working_order, ['holding'])
      new_email.body = @email.to_s
      new_email.date = Time.now
      new_email.deliver

      UpdateOrderDateCustomerNotified.exec_now({:order_id => @order_id})
      on_success("Email sent to #{@first_name} #{@last_name} (#{@email}) for Order #{@order_id}.")
   end
end
