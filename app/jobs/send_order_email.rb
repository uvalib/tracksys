class SendOrderEmail < BaseJob

   def set_originator(message)
      @status.update_attributes( :originator_type=> "Order", :originator_id=>message[:order].id )
   end

   def do_workflow(message)
      @order = message[:order]
      @email = @order.email

      # recreate the email but there is no longer a need to pass correct
      # information because the body will be drawn from order.email
      new_email = OrderMailer.web_delivery(@order, ['holding'])
      new_email.body = @email.to_s
      new_email.date = Time.now
      new_email.deliver

      @order.update_attribute(:date_customer_notified, Time.now)
      on_success("Email sent to #{@order.customer.email} (#{@email}) for Order #{@order.id}.")

      CreateInvoice.exec_now({:order => @order}, self)
   end
end
