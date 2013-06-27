class AddDplaToMasterFiles < ActiveRecord::Migration
  def change
    add_column :master_files, :dpla, :boolean
  end
end
