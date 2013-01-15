class ReportMailer < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  default from: "digitalservices@virginia.edu", 
          bcc: "andrew.curley@gmail.com",
          reply_to: "digitalservices@virginia.edu"

  # def send_fee_estimate(order)
  #   @order = order
  #   @customer = order.customer
    
  #   if Rails.env == "development" || Rails.env == "test"
  #     address = 'merchantofcville@gmail.com'
  #   else
  #     address = @customer.email
  #   end

  #   mail to: address, subject: "UVA Digitization Services - Request #{order.id} Estimated Fee"
  # end

  def send_dl_manifest(staff_member)
    @staff_member = staff_member
    attachments["dl_manifest_#{Time.now.strftime('%Y%m%d')}.xlsx"] = File.read("/tmp/dl_manifest_#{Time.now.strftime('%Y%m%d')}.xlsx")
    mail to: @staff_member.email, subject: "DCS Digital Library Manifest as of #{Time.now.strftime("%B %-d, %Y")}"
  end
end
