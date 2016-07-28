class AddItemToMasterFile < ActiveRecord::Migration
  def change
     add_reference :master_files, :item, index: true
  end
end
