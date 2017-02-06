class CreateNotes < ActiveRecord::Migration
   def change
      create_table :problems do |t|
         t.string :name
      end

      create_table :notes do |t|
         t.references :staff_member, index: true
         t.references :task, index: true
         t.references :problem, index: true
         t.text :note
         t.integer :note_type        # enum note_type: [:comment, :suggestion, :problem, :item_condition]
         t.timestamps null: false
      end
   end
end
