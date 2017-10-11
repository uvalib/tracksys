class AddLabelToProblems < ActiveRecord::Migration[5.1]
  def change
     add_column :problems, :label, :string
  end
end
