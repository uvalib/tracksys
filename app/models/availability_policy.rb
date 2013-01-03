require "#{Hydraulics.models_dir}/availability_policy"

class AvailabilityPolicy

  def xacml_policy_url
    return "#{self.repository_url}/fedora/objects/#{self.pid}/datastreams/XACML/content"
  end
end
