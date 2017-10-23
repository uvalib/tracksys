class CreateNotesProblems < ActiveRecord::Migration[5.1]
   # faux models to make migration work
   class Note < ApplicationRecord
      enum note_type: [:comment, :suggestion, :problem, :item_condition]
      belongs_to :staff_member
      belongs_to :problem
      belongs_to :project
      belongs_to :step
      has_and_belongs_to_many :problems
   end

   def up
      puts "Creating notes_problems table..."
      create_table :notes_problems, id: false do |t|
         t.belongs_to :note, index: true
         t.belongs_to :problem, index: true
      end

      puts "Migrating existing problems to notes_problems..."
      cnt = 0
      Note.where(note_type: 2).each do |n|
         n.problems << n.problem
         cnt += 1
      end
      puts "Migrated #{cnt} problems"

      # retire notes problem column and remove notes count from problems
      # counts can be found using the new workflow reports
      puts "Clean up old columns..."
      remove_reference :notes, :problem, index: true
      remove_column :problems, :notes_count, :integer
      puts "DONE"
   end

   def down
      # not reversible
   end
end
