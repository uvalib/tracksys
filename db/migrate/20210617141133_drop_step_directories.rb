class DropStepDirectories < ActiveRecord::Migration[5.2]
  def change
    remove_column :steps, :start_dir, :string
    remove_column :steps, :finish_dir, :string
    remove_column :steps, :manual, :boolean, default: false
  end
end
