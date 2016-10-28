class AddMetadataToMasterFile < ActiveRecord::Migration
  def change
     add_reference :master_files, :metadata, index: true
  end
end
