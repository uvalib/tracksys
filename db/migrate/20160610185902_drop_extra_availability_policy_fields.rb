class DropExtraAvailabilityPolicyFields < ActiveRecord::Migration
  def change
     remove_foreign_key :components, :availability_policy
     remove_column  :components, :availability_policy_id, :integer
     remove_foreign_key :master_files, :availability_policy
     remove_column  :master_files, :availability_policy_id, :integer
     remove_foreign_key :units, :availability_policy
     remove_column  :units, :availability_policy_id, :integer
  end
end
