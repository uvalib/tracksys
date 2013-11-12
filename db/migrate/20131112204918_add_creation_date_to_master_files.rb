class AddCreationDateToMasterFiles < ActiveRecord::Migration
  def change
    add_column :master_files, :creation_date, :date
  end
end
