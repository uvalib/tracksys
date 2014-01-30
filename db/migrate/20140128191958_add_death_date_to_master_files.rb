class AddDeathDateToMasterFiles < ActiveRecord::Migration
  def change
    add_column :master_files, :creator_death_date, :string
  end
end
