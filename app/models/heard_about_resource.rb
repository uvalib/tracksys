require "#{Hydraulics.models_dir}/heard_about_resource"

class HeardAboutResource

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description  
  
end
