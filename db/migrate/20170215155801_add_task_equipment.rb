class AddTaskEquipment < ActiveRecord::Migration
   def change
      remove_column :tasks, :camera, :string
      remove_column :tasks, :lens, :string
      remove_column :tasks, :resolution, :string
      add_column :tasks, :viu_number, :string
      add_column :tasks, :capture_resolution, :integer
      add_column :tasks, :resized_resolution, :integer
      add_column :tasks, :resolution_note, :string

      create_table :task_equipment do |t|
         t.references :task, index: true
         t.references :equipment, index: true
         t.timestamps
      end
   end
end
