class DropIsApprovedFromMetadata < ActiveRecord::Migration[5.2]
  def change
     remove_column :metadata, :is_approved, :boolean
  end
end
