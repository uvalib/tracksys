class UpgradeUseRights < ActiveRecord::Migration

  def change
    add_column :use_rights, :bibls_count, :integer, :default => 0
    add_column :use_rights, :components_count, :integer, :default => 0
    add_column :use_rights, :master_files_count, :integer, :default => 0
    add_column :use_rights, :units_count, :integer, :default => 0

    say "Updating use_right.orders_count, use_right.units_count, use_right.components_counts and use_right.master_files_count"
    UseRight.find(:all).each {|u|
      UseRight.update_counters u.id, :orders_count => u.orders.count
      UseRight.update_counters u.id, :units_count => u.units.count
      UseRight.update_counters u.id, :components_count => u.components.count
      UseRight.update_counters u.id, :master_files_count => u.master_files.count
    }
  end
end