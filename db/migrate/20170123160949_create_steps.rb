class CreateSteps < ActiveRecord::Migration
  def change
    create_table :steps do |t|
      t.string :name
      t.text :description
      t.integer :sequence
      t.string :start_dir
      t.string :finish_dir
      t.references :workflow, index: true
      t.timestamps null: false
    end
  end
end
