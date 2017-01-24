class CreateWorkflows < ActiveRecord::Migration
  def change
    create_table :workflows do |t|
      t.string :name
      t.text :description
      t.timestamps null: false
    end
  end
end
