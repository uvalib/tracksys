class AddAncestryToComponents < ActiveRecord::Migration
  def change
    add_column :components, :ancestry, :string
    add_index :components, :ancestry
  end
end
