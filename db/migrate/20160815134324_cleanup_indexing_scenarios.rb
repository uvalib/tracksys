class CleanupIndexingScenarios < ActiveRecord::Migration
  def change
     remove_column :indexing_scenarios, :pid, :string
     remove_column :indexing_scenarios, :repository_url, :string
     remove_column :indexing_scenarios, :datastream_name, :string
  end
end
