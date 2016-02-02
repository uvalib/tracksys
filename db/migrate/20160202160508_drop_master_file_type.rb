class DropMasterFileType < ActiveRecord::Migration
  def up
     remove_column :master_files, :type
  end

  def down
     add_column :master_files, :type, :string
  end
end
