class UpgradeAcademicStatuses < ActiveRecord::Migration

  def change
    add_index :academic_statuses, :name, :unique => true
    add_column :academic_statuses, :customers_count, :integer, :default => 0
  end

end