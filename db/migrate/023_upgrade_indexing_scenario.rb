class UpgradeIndexingScenario < ActiveRecord::Migration

  def change
    add_column :indexing_scenarios, :bibls_count, :integer, :default => 0
    add_column :indexing_scenarios, :components_count, :integer, :default => 0
    add_column :indexing_scenarios, :master_files_count, :integer, :default => 0
    add_column :indexing_scenarios, :units_count, :integer, :default => 0

    say "Updating indexing_scenario.orders_count, indexing_scenario.units_count, indexing_scenario.components_counts and indexing_scenario.master_files_count"
    IndexingScenario.find(:all).each {|i|
      IndexingScenario.update_counters i.id, :orders_count => i.orders.count
      IndexingScenario.update_counters i.id, :units_count => i.units.count
      IndexingScenario.update_counters i.id, :components_count => i.components.count
      IndexingScenario.update_counters i.id, :master_files_count => i.master_files.count
    }
  end
end