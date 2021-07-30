class DropWorkflowBaseDir < ActiveRecord::Migration[5.2]
  def change
    remove_column :workflows, :base_directory, :string
  end
end
