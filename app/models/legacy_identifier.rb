require "#{Hydraulics.models_dir}/legacy_identifier"

class LegacyIdentifier
  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_and_belongs_to_many :units
end
# == Schema Information
#
# Table name: legacy_identifiers
#
#  id                :integer(4)      not null, primary key
#  label             :string(255)
#  description       :string(255)
#  legacy_identifier :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#

