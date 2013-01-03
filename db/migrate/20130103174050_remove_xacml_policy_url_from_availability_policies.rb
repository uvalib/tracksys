class RemoveXacmlPolicyUrlFromAvailabilityPolicies < ActiveRecord::Migration
  def change
    remove_column :availability_policies, :xacml_policy_url
  end
end
