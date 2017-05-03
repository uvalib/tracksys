class AddCountToProblems < ActiveRecord::Migration
  def change
     add_column :problems, :notes_count, :integer, default: 0
  end
end
