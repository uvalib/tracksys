class OrderMailer < ActionMailer::Base
  default from: "digitalservices@virginia.edu"

  def send_fee_estimate(order)
    @order = order
    @customer = order.customer
    mail to: @order.customer.email, subject: "UVA Digitization Services - Request #{order.id} Estimated Fee"
  end
  
  def deliver_order(order)
    @order = order
    @customer = order.customer
    mail to: @order.customer.email, subject: "UVA Digitization Services - Order #{order.id} Complete"
  end
end
