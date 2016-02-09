class RemoveArchive < ActiveRecord::Migration
   def up
      remove_foreign_key :units, :archive
      remove_column :units, :archive_id
      drop_table :archives
   end

   def down
      create_table :archives do |t|
         t.string :name
         t.string :directory
         t.string :description
         t.integer :units_count
      end
      add_column :units, :archive_id, :integer
   end
end
