class UpdateMasterFileDescription < ActiveRecord::Migration
  def change
     change_column :master_files, :description, :text
  end
end
