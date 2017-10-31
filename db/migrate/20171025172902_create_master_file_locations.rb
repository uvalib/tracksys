class CreateMasterFileLocations < ActiveRecord::Migration[5.1]
   def up
      create_table :container_types do |t|
         t.string :name, null: false
      end
      ContainerType.create([{name: "Box"}, {name: "Oversize Box"}, {name: "Tray"}])

      create_table :locations do |t|
         t.belongs_to :container_type, index: true
         t.string :container_id, null: false
         t.string :folder_id, null: false
      end

      create_table :master_file_locations, id: false do |t|
         t.belongs_to :location, index: true
         t.belongs_to :master_file, index: true
      end

      puts "Migrate exiting folder info..."
      Metadata.where("folder_id <> ''").each do |m|
         cnt = 0
         puts "   Box #{m.box_id}, Folder #{m.folder_id}"
         l = Location.create(container_type_id: 1, container_id: m.box_id, folder_id: m.folder_id)
         m.master_files.each do |mf|
            cnt +=1
            mf.location = l
         end
         puts "   ....migrated [#{cnt}] master files."
      end
      puts "MIGRATION DONE; cleaning up old columns..."
      remove_column :metadata, :folder_id, :string
      remove_column :metadata, :box_id, :string
   end

   def down
      drop_table :locations
      drop_table :location_types
      drop_table :master_file_locations
      add_column :metadata, :folder_id, :string
      add_column :metadata, :box_id, :string
   end

end
