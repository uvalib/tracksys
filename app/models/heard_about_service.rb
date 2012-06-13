require "#{Hydraulics.models_dir}/heard_about_service"

class HeardAboutService
  default_scope :order => :description
  scope :for_request_form, where(:is_approved => true).where(:is_internal_use_only => false)
end
