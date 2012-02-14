class UpgradeDepartments < ActiveRecord::Migration

  def change
    add_column :departments, :customers_count, :integer, :default => 0
  end

end
