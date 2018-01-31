class DropUnitCheckoutFields < ActiveRecord::Migration[5.1]
  def change
     remove_column :units, :date_materials_received, :datetime
     remove_column :units, :date_materials_returned, :datetime
     remove_column :units, :checked_out, :boolean
  end
end
