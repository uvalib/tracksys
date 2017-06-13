class AddCollectionInfoToMetadata < ActiveRecord::Migration
  def change
     add_column :metadata, :collection_id, :string
     add_column :metadata, :box_id, :string
     add_column :metadata, :folder_id, :string
  end
end
