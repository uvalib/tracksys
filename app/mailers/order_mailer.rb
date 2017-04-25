class OrderMailer < ActionMailer::Base
   add_template_helper(ApplicationHelper)

   default  from: "digitalservices@virginia.edu",
            reply_to: "digitalservices@virginia.edu"

   def send_fee_estimate(order)
      @order = order
      @customer = order.customer
      address = @customer.email
      if Settings.send_customer_email == "false"
         address = Settings.alternate_email_recipient
      end

      mail to: address, subject: "UVA Digital Production Group - Request #{order.id} Estimated Fee"
   end

   def request_confirmation(request)
      @request = request
      @customer = request.customer
      address = @customer.email
      if Settings.send_customer_email == "false"
         address = Settings.alternate_email_recipient
      end

      mail to: address, subject: "UVA Digital Production Group - Request ##{@request.id} Confirmation", :css => :email
   end

   def web_delivery(order, delivery_files)
      @order = order
      @customer = order.customer
      @delivery_files = delivery_files
      address = @customer.email
      if Settings.send_customer_email == "false"
         address = Settings.alternate_email_recipient
      end

      # Pass fees to email if there is a fee and it is not equal to $0.00
      if order.fee_estimated and order.fee_actual
         if not order.fee_actual.to_i.eql?(0)
            @fee = order.fee_actual
         end
      end

      mail to: address, subject: "UVA Digital Production Group - Order # #{order.id} Complete"
   end
end
