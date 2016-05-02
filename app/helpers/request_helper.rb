module RequestHelper
  # Returns a string containing HTML for display of Rails "flash"
  # notices.

  def get_flash
    out = ''
    out += '<div class="flashes">'
    if flash[:notice]
      out += '<div class="flash flash_type_notice">'
      out += '<p>' + html_escape(flash[:notice]) + '</p>'
      out += '</div>'
    end
    if flash[:error]
      out += '<div class="flash flash_type_error">'
      out += '<p>' + html_escape(flash[:error]) + '</p>'
      out += '</div>'
    end
    out += '</div>'
    return out
  end
end
