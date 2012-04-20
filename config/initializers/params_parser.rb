# ActionDispatch::ParamsParser.class_eval do

#   private
#   def parse_formatted_parameters(env)
#     # request = Request.new(env)
#     # logger.info "#{request.env["HTTP_USER_AGENT"]}"
#     # mime_type = Mime::XML if env["HTTP_USER_AGENT"] =~ /Oxygen/ && env["REQUEST_METHOD"] == "PUT"
#     super if defined?(super)
#     mime_type = content_type_from_legacy_post_data_format_header(env) ||
#           request.content_mime_type || Mime::XML if env["HTTP_USER_AGENT"] =~ /Oxygen/ && env["REQUEST_METHOD"] == "PUT"
#     super if defined?(super)
#   end
  
# end