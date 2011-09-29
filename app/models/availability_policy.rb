# == Schema Information
#
# Table name: availability_policies
#
#  id               :integer         not null, primary key
#  name             :string(255)
#  xacml_policy_url :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#

require "#{Hydraulics.models_dir}/availability_policy"

class AvailabilityPolicy
end
