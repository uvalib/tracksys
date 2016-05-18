class RemoveUnusedComponentFields < ActiveRecord::Migration
  def change
     remove_column :components, :physical_desc, :text
     remove_column :components, :scope_content, :text
     remove_column :components, :parent_ead_ref_id, :integer
     remove_column :components, :ead_ref_id, :integer
  end
end
