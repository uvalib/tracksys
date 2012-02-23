class UpgradeArchives < ActiveRecord::Migration
  def change
    change_table(:archives, :bulk => true) do |t|
      t.string :description
      t.integer :units_count, :default => 0
    end
  end
end
