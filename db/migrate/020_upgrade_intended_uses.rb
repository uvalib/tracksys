class UpgradeIntendedUses < ActiveRecord::Migration
  def change
    change_table(:intended_uses, :bulk => true) do |t|
      t.remove_index :name => 'description'
      t.index :description, :unique => true
      t.integer :units_count, :default => 0
    end
  end
end
