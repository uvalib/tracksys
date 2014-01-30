class AddJp2ModelToMasterfiles < ActiveRecord::Migration
  def change
    add_column :master_files, :type, :string
  end
end
