class DropAvaiabilityCountFields < ActiveRecord::Migration
  def change
     remove_column  :availability_policies, :components_count, :integer
     remove_column  :availability_policies, :master_files_count, :integer
     remove_column  :availability_policies, :units_count, :integer
     remove_column  :availability_policies, :repository_url, :string
  end
end
