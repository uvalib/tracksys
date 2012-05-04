require "#{Hydraulics.models_dir}/intended_use"

class IntendedUse
  default_scope :order => :description

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description  
  
end
