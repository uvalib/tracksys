class AddTextTypeToMasterFile < ActiveRecord::Migration
  def change
     add_column :master_files, :text_source, :integer
  end
end
