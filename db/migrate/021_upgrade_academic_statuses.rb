class UpgradeAcademicStatuses < ActiveRecord::Migration
  def change
    change_table(:academic_statuses, :bulk => true) do |t|
      t.index :name, :unique => true
      t.integer :customers_count, :default => 0
    end
  end
end
