class UpgradeIndexingScenario < ActiveRecord::Migration

  def change
    add_column :indexing_scenarios, :bibls_count, :integer, :default => 0
    add_column :indexing_scenarios, :components_count, :integer, :default => 0
    add_column :indexing_scenarios, :master_files_count, :integer, :default => 0
    add_column :indexing_scenarios, :units_count, :integer, :default => 0
  end
end