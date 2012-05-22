class OrderMailer < ActionMailer::Base
  default from: "digitalservices@virginia.edu", 
          bcc: "andrew.curley@gmail.com",
          reply_to: "digitalservices@virginia.edu"

  def send_fee_estimate(order)
    @order = order
    @customer = order.customer
    mail to: @order.customer.email, subject: "UVA Digitization Services - Request #{order.id} Estimated Fee"
  end

  def dvd_delivery(order, dvd_delivery_location)
    @order = order
    @customer = order.customer
    @dvd_delivery_location = dvd_delivery_location

    # Pass fees to email if there is a fee and it is not equal to $0.00
    if order.fee_estimated and order.fee_actual
      if not order.fee_actual.to_i.eql?(0)
        @fee = order.fee_actual
      end
    end

    mail to: @order.customer.email, subject: "UVA Digitization Services - Order #{order.id} Complete"
  end
  
  def web_delivery(order, delivery_files)
    @order = order
    @customer = order.customer
    @delivery_files = delivery_files

    # Pass fees to email if there is a fee and it is not equal to $0.00
    if order.fee_estimated and order.fee_actual
      if not order.fee_actual.to_i.eql?(0)
        @fee = order.fee_actual
      end
    end

    mail to: @order.customer.email, subject: "UVA Digitization Services - Order # #{order.id} Complete"
  end
end
