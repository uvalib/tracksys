class DropRetiredColumns < ActiveRecord::Migration
  def change
     remove_foreign_key :master_files, :indexing_scenario
     remove_foreign_key :master_files, :use_right
     remove_foreign_key :units, :indexing_scenario

     remove_column  :master_files, :indexing_scenario_id, :integer
     remove_column  :master_files, :use_right_id, :integer
     remove_column  :master_files, :desc_metadata, :string
     remove_column  :master_files, :discoverability, :boolean

     remove_column  :units, :indexing_scenario_id, :integer
     remove_column  :units, :master_file_discoverability, :boolean
  end
end
