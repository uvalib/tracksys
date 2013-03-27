class RemoveMasterFilesCountFromBibls < ActiveRecord::Migration
  def up
    remove_column :bibls, :master_files_count
  end

  def down
    add_column :bibls, :master_files_count, :integer
  end
end
