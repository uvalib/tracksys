class DropUnusedDplaFlagFromMasterFiles < ActiveRecord::Migration
  def change
     remove_column  :master_files, :dpla, :boolean
  end
end
