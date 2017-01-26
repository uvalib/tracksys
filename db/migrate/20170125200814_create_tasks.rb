class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.references :workflow, index: true
      t.references :unit, index: true
      t.integer :priority, default: 0
      t.date :added_on
      t.date :due_on
      t.integer :condition          # enum condition: [:good, :bad]
      t.integer :category           # enum category: [:book, :manuscript, :slide, :cruse_scan]   
      t.timestamps null: false
    end
  end
end
