class UpgradeAgencies < ActiveRecord::Migration
  def change
    change_table(:agencies, :bulk => true) do |t|
      t.integer :orders_count, :default => 0
    end
  end
end
