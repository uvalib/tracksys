class CreateSteps < ActiveRecord::Migration
  def change
    create_table :steps do |t|
      t.integer :step_type, default: 3     # enum step_type: [:first, :last, :error, :normal]
      t.string :name
      t.text :description
      t.string :start_dir
      t.string :finish_dir
      t.boolean :propagate_owner, default: false
      t.references :workflow, index: true
      t.references :next_step, references: :step, index: true
      t.references :fail_step, references: :step, index: true
      t.timestamps null: false
    end
  end
end
