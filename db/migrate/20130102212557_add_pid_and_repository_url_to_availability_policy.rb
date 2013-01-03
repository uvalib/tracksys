class AddPidAndRepositoryUrlToAvailabilityPolicy < ActiveRecord::Migration
  def change
    add_column :availability_policies, :repository_url, :string
    add_column :availability_policies, :pid, :string
  end
end
