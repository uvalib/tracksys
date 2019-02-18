class AddCommentToMetadataVesions < ActiveRecord::Migration[5.2]
  def change
     add_column :metadata_versions, :comment, :text
  end
end
