class DropDirectoryNameFromContainerType < ActiveRecord::Migration[5.2]
  def change
      remove_column :container_types, :directory_name, :string
  end
end
