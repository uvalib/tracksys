class AddCreationDateToMasterFiles < ActiveRecord::Migration
  def change
    add_column :master_files, :creation_date, :date
    add_column :master_files, :primary_author, :string
  end
end
