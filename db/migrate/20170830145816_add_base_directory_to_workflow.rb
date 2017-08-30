class AddBaseDirectoryToWorkflow < ActiveRecord::Migration[5.1]
   def change
      add_column :workflows, :base_directory, :string, default: Figaro.env.production_mount
   end
end
