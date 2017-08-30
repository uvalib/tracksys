class AddOcrToUnit < ActiveRecord::Migration[5.1]
  def change
     add_column :units, :ocr_master_files, :boolean, default: false
  end
end
