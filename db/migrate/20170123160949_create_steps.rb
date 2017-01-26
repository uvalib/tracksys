class CreateSteps < ActiveRecord::Migration
  def change
    create_table :steps do |t|
      t.integer :step_type, default: :normal     # enum step_type: [:first, :last, :error, :normal]
      t.string :name
      t.text :description
      t.string :start_dir
      t.string :finish_dir
      t.references :workflow, index: true
      t.integer :next_step_id, index: true
      t.integer :fail_step_id, index: true
      t.timestamps null: false
    end
  end
end
