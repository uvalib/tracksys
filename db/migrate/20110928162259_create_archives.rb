class CreateArchives < ActiveRecord::Migration
  def change
    create_table :archives do |t|
      t.string :name
      t.string :description
      t.integer :units_count, :default => 0

      t.timestamps
    end
    
    add_index :archives, :name
  end
end