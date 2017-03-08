class AddEquipmentStatus < ActiveRecord::Migration
  def change
     add_column :equipment, :status, :integer, default: 0  # enum status: [:active, :inactive, :retired]
  end
end
