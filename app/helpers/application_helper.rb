require "#{Hydraulics.helpers_dir}/application_helper"

module ApplicationHelper

  def format_date(date)
    begin
      return date.strftime("%B %d, %Y")
    rescue Exception => e
      return nil
    end
  end

  def format_email_in_sidebar(email)
    begin
      return email.gsub(/(@)/, "@\r").delete(' ')
    rescue Exception => e
      return nil
    end
  end

end
