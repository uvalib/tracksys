class AddWorkstationStatus < ActiveRecord::Migration
  def change
     add_column :workstations, :status, :integer, default: 0  # enum status: [:active, :maintenance, :retired]
  end
end
