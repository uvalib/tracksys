class ReportMailer < ActionMailer::Base
   add_template_helper(ApplicationHelper)

   default  from: "digitalservices@virginia.edu",
            reply_to: "digitalservices@virginia.edu"

   def send_dl_manifest(staff_member)
      @staff_member = staff_member
      attachments["dl_manifest_#{Time.now.strftime('%Y%m%d')}.xlsx"] = File.read("#{Rails.root}/tmp/dl_manifest_#{Time.now.strftime('%Y%m%d')}.xlsx")
      mail to: @staff_member.email, subject: "DCS Digital Library Manifest as of #{Time.now.strftime("%B %-d, %Y")}"
   end

   def stats_report_complete(staff_member, path)
      @staff_member = staff_member
      @stats_path = path
      mail to: @staff_member.email, subject: "Stats report ready"
   end
end
