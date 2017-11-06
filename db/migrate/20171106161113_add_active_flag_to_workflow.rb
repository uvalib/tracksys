class AddActiveFlagToWorkflow < ActiveRecord::Migration[5.1]
  def change
     add_column :workflows, :active, :boolean, default: true
  end
end
