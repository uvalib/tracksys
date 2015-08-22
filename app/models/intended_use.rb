require "#{Hydraulics.models_dir}/intended_use"

class IntendedUse
  default_scope :order => :description

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description  
  
end
# == Schema Information
#
# Table name: intended_uses
#
#  id                          :integer(4)      not null, primary key
#  description                 :string(255)
#  is_internal_use_only        :boolean(1)      default(FALSE), not null
#  is_approved                 :boolean(1)      default(FALSE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  units_count                 :integer(4)      default(0)
#  deliverable_format          :string(255)
#  deliverable_resolution      :string(255)
#  deliverable_resolution_unit :string(255)
#

