class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :workflow, index: true
      t.references :unit, index: true
      t.references :owner, references: :staff_member
      t.integer :priority, default: 0
      t.date :due_on
      t.integer :condition          # enum condition: [:good, :bad]
      t.integer :category           # enum category: [:book, :manuscript, :slide, :cruse_scan]
      t.datetime :added_at
      t.datetime :started_at
      t.datetime :finished_at
    end
  end
end
