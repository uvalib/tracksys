require "#{Hydraulics.models_dir}/bibl"

class Bibl

  after_update :fix_updated_counters

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :title

end
