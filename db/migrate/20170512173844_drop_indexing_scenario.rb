class DropIndexingScenario < ActiveRecord::Migration
  def up
     remove_foreign_key :components, :indexing_scenario
     remove_reference :components, :indexing_scenario, index: true
     remove_foreign_key :metadata, :indexing_scenario
     remove_reference :metadata, :indexing_scenario, index: true
     drop_table :indexing_scenarios
  end

  def down
  end
end
