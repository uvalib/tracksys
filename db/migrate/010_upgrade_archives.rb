class UpgradeArchives < ActiveRecord::Migration
  def change
    add_column :archives, :description, :string
    add_column :archives, :units_count, :integer, :default => 0
    Archive.find(:all).each {|a|
      Archive.update_counters a.id, :units_count => a.units.count
    }
  end
end
