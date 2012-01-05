class UpgradeAgencies < ActiveRecord::Migration
  def change
    add_column :agencies, :orders_count, :integer, :default => 0
    Agency.find(:all).each {|a|
      Agency.update_counters a.id, :orders_count => a.orders.count
    }
  end
end
