require "#{Hydraulics.models_dir}/heard_about_resource"

class HeardAboutResource
  default_scope :order => :description

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description  
  
end
