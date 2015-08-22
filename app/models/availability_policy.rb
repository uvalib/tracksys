require "#{Hydraulics.models_dir}/availability_policy"

class AvailabilityPolicy

  def xacml_policy_url
    return "#{self.repository_url}/fedora/objects/#{self.pid}/datastreams/XACML/content"
  end
end
# == Schema Information
#
# Table name: availability_policies
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  bibls_count        :integer(4)      default(0)
#  components_count   :integer(4)      default(0)
#  master_files_count :integer(4)      default(0)
#  units_count        :integer(4)      default(0)
#  created_at         :datetime        not null
#  updated_at         :datetime        not null
#  repository_url     :string(255)
#  pid                :string(255)
#

