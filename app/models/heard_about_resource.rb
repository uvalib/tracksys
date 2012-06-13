require "#{Hydraulics.models_dir}/heard_about_resource"

class HeardAboutResource
  default_scope :order => :description
  scope :for_request_form, where(:is_approved => true).where(:is_internal_use_only => false)
  
  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description  
  
end
