class AddCompleteScanToUnits < ActiveRecord::Migration
  def change
     add_column :units, :complete_scan, :boolean, :default=>false
  end
end
