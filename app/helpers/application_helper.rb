require "#{Hydraulics.helpers_dir}/application_helper"

include TweetButton

module ApplicationHelper

  def format_boolean_as_yes_no(boolean)
    if boolean
      return 'Yes'
    else
      return 'No'
    end
  end

  def format_boolean_as_present(boolean)
    if boolean
      return 'Available'
    else
      return 'None available'
    end
  end

  def format_date(date)
    begin
      return date.strftime("%m / %d / %Y")
    rescue Exception => e
      return nil
    end
  end

  def format_datetime(datetime)
    begin
      return datetime.strftime("%m / %d / %Y %l:%M:%S %P")
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

  # Since Kaminari needs a "pagination object" to operate on, it is essential to turn a single 
  # object into an Array that Kaminari can use.
  # def pagify(object)
  #   return Kaminari.paginate_array(Array[object])
  # end
end