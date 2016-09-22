class DropUnusedCounters < ActiveRecord::Migration
  def change
     remove_column  :indexing_scenarios, :units_count, :integer
     remove_column  :indexing_scenarios, :master_files_count, :integer
     remove_column  :use_rights, :master_files_count, :integer
  end
end
