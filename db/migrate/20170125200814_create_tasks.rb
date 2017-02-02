class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :workflow, index: true
      t.references :unit, index: true
      t.references :owner, references: :staff_member
      t.references :current_step, references: :step
      t.integer :priority, default: 0
      t.date :due_on
      t.string :camera
      t.string :lens
      t.string :resolution
      t.integer :item_condition      # enum item_condition: [:good, :bad]
      t.integer :item_type           # enum item_type: [:book, :manuscript, :slide, :cruse_scan]
      t.datetime :added_at
      t.datetime :started_at
      t.datetime :finished_at
    end
  end
end
