class UpdateTaskCategories < ActiveRecord::Migration
  def change
     remove_column :tasks, :item_type, :integer
     add_reference :tasks, :category, index: true
  end
end
