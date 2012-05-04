class ApplicationController < ActionController::Base
  protect_from_forgery

  def update
    if env["HTTP_USER_AGENT"] =~ /Oxygen/ && env["REQUEST_METHOD"] == "PUT"
      xml = Hash.from_xml(request.body.read)
      params.merge!(xml)
    end
  end
end
