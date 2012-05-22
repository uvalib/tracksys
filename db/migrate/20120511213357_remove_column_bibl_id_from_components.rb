class RemoveColumnBiblIdFromComponents < ActiveRecord::Migration
  def change
    remove_column :components, :bibl_id
  end
end
