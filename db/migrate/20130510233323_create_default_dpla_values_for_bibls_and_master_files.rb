class CreateDefaultDplaValuesForBiblsAndMasterFiles < ActiveRecord::Migration
  def up
    change_column :bibls, :dpla, :boolean, :default => false
    change_column :master_files, :dpla, :boolean, :default => false
  end
  
  def down
    # No need to do anything here
  end
end
