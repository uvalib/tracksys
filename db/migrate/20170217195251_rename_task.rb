class RenameTask < ActiveRecord::Migration
   def change
      rename_table :tasks, :projects
      rename_table :task_equipment, :project_equipment
      rename_column :project_equipment, :task_id, :project_id
      rename_column :assignments, :task_id, :project_id
      rename_column :notes, :task_id, :project_id
      rename_column :categories, :tasks_count, :projects_count
   end
end
