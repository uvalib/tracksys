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

  # Truncates input string (to number of words specified, using word
  # boundaries) and returns resulting string.
  def truncate_words(text, length = 20, end_string = ' ...')
    if text.nil?
      return ''
    else
      words = text.split()
      return words[0..(length-1)].join(' ') + (words.length > length ? end_string : '')
    end
  end
end
