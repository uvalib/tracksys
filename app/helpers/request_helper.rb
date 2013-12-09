module RequestHelper
  # Returns a string containing HTML for display of Rails "flash"
  # notices.

  def required_field_value
    # Determined these valued from http://caniuse.com/#feat=form-validation
    if browser.firefox? && browser.version > "3.6" || browser.chrome? && browser.version > "17" || browser.ie? && browser.version > "9" || browser.opera? && browser.version > "11.5"
      return true
    else
      return false
    end
  end

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

  def get_jpeg_only_uses
    uses = []
    uses = IntendedUse.external_use.collect { |i|
      [i.description, i.id] if i.deliverable_format == "jpeg"
      }
    uses.compact
  end
end
