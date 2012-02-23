class UpgradeDepartments < ActiveRecord::Migration
  def change
    change_table(:departments, :bulk => true) do |t|
      t.integer :customers_count, :default => 0
    end
  end
end
