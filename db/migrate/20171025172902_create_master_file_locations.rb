class CreateMasterFileLocations < ActiveRecord::Migration[5.1]
   def up
      create_table :locations do |t|
         t.belongs_to :metadata, index: true
         t.string :folder, null: false
      end

      create_table :master_file_locations, id: false do |t|
         t.belongs_to :location, index: true
         t.belongs_to :master_file, index: true
      end

      puts "Migrate exiting folder info..."
      Metadata.where("folder_id <> ''").each do |m|
         cnt = 0
         puts "   Box #{m.box_id}, Folder #{m.folder_id}"
         l = Location.create(metadata: m, folder: m.folder_id)
         m.master_files.each do |mf|
            cnt +=1
            mf.location = l
         end
         puts "   ....migrated [#{cnt}] master files."
      end
      puts "MIGRATION DONE; cleaning up old columns..."
      remove_column :metadata, :folder_id, :string
      rename_column :metadata, :box_id, :box
   end

   def down
      drop_table :locations
      drop_table :master_file_locations
      add_column :metadata, :folder_id, :string
      rename_column :metadata, :box, :box_id
   end

end
