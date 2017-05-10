class RenameParentBibl < ActiveRecord::Migration
  def change
     rename_column :metadata, :parent_bibl_id, :parent_metadata_id
  end
end
