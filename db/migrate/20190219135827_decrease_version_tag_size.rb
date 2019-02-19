class DecreaseVersionTagSize < ActiveRecord::Migration[5.2]
  def change
     change_column :metadata_versions, :version_tag, :string, :limit => 40
  end
end
