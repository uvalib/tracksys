require "#{Hydraulics.models_dir}/legacy_identifier"

class LegacyIdentifier
  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_and_belongs_to_many :units
end
