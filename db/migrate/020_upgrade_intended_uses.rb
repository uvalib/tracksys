class UpgradeIntendedUses < ActiveRecord::Migration
  def change
    change_table(:intended_uses, :bulk => true) do |t|
      t.remove_index :description
    end
    # It is not possible to change index or tear down and create the same index in the
    # same transaction, it is necessary to create two transactions.
    change_table(:intended_uses, :bulk => true) do |t|
      t.index :description, :unique => true
      t.integer :units_count, :default => 0
    end
  end
end
