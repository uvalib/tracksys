class UpgradeIntendedUses < ActiveRecord::Migration

  def change
    remove_index :intended_uses, :column => :description
    add_index :intended_uses, :description, :unique => true
  end

end