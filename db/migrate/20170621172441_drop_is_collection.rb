class DropIsCollection < ActiveRecord::Migration
  def change
     remove_column :metadata, :is_collection, :boolean
  end
end
