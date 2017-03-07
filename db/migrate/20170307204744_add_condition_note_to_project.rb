class AddConditionNoteToProject < ActiveRecord::Migration
  def change
     add_column :projects, :condition_note, :text
  end
end
