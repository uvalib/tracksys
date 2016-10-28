class NotificationsMailer < ActionMailer::Base

   default  from: "digitalservices@virginia.edu",
            reply_to: "digitalservices@virginia.edu"

   def xml_download_complete(staff_member, unit, path)
      @download_path = path
      @unit = unit
      mail to: staff_member.email, subject: "XML Download Complete"
   end
end
