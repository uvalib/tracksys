class AddDurationToAssignment < ActiveRecord::Migration
  def change
     add_column :assignments, :duration_minutes, :integer
  end
end
