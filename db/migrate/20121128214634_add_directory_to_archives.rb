class AddDirectoryToArchives < ActiveRecord::Migration
  def change
    add_column :archives, :directory, :string
  end
end
