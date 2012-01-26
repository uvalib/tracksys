# == Schema Information
#
# Table name: heard_about_resources
#
#  id                   :integer         not null, primary key
#  description          :string(255)
#  is_approved          :boolean         default(FALSE), not null
#  is_internal_use_only :boolean         default(FALSE), not null
#  created_at           :datetime
#  updated_at           :datetime
#

require "#{Hydraulics.models_dir}/heard_about_resource"

class HeardAboutResource

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description  
  
end
