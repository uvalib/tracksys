class CreateHeardAboutResources < ActiveRecord::Migration
  def change
    create_table :heard_about_resources do |t|
      t.string :description
      t.boolean :is_approved, :null => false, :default => 0
      t.boolean :is_internal_use_only, :null => false, :default => 0

      t.timestamps
    end
    
    add_index :heard_about_resources, :description
  end
end