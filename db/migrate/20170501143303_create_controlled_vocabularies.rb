class CreateControlledVocabularies < ActiveRecord::Migration

   def up
      # Create the tables
      puts "Create tables for controlled vocabularies..."
      create_table :genres do |t|
         t.string :name
      end
      create_table :resource_types do |t|
         t.string :name
      end

      # Seed them
      puts "Seeding controlled vocabularies..."
      src = [{file: 'genres.txt', type: "Genre"}, {file: 'resource_types.txt', type: "ResourceType"}]
      src.each do |s|
         txt = File.read(Rails.root.join('data', s[:file]))
         txt.each_line do |v|
            if s[:type] == "Genre"
               Genre.create(name: v.strip)
            else
               ResourceType.create(name: v.strip)
            end
         end
      end

      # Create new ID fields in metadata...
      puts "Adding new metadata fields..."
      rename_column :metadata, :genre, :genre_str
      rename_column :metadata, :resource_type, :resource_type_str
      add_reference :metadata, :genre, index: true
      add_reference :metadata, :resource_type, index: true

      # Migrate data...
      puts "Migrating existing data..."
      genres = Genre.all
      types = ResourceType.all
      Metadata.where("resource_type_str is not null or genre_str is not null").each do |m|
         if !m.resource_type_str.blank?
            types.each do |t|
               if t.name.downcase == m.resource_type_str.downcase.strip
                  m.update(resource_type_id: t.id)
                  break
               end
            end
         end
         if !m.genre_str.blank?
            genres.each do |t|
               if t.name.downcase == m.genre_str.downcase.strip
                  m.update(genre_id: t.id)
                  break
               end
            end
         end
      end

      # Cleanup old string fields...
      puts "Removing old string fields..."
      remove_column :metadata, :genre_str, :string
      remove_column :metadata, :resource_type_str, :string
   end

   def down
      puts "Putting back old string fields..."
      add_column :metadata, :genre_str, :string
      add_column :metadata, :resource_type_str, :string

      puts "Migrating lookups into string data..."
      genres = Genre.all
      types = ResourceType.all
      Metadata.where("resource_type_id is not null or genre_id is not null").each do |m|
         if !m.resource_type_id.blank?
            types.each do |t|
               if t.id == m.resource_type_id
                  m.update(resource_type_str: t.name.downcase)
                  break
               end
            end
         end
         if !m.genre_id.blank?
            genres.each do |t|
               if t.id == m.genre_id
                  m.update(genre_str: t.name.downcase)
                  break
               end
            end
         end
      end

      puts "Removing references..."
      remove_reference :metadata, :genre, index: true
      remove_reference :metadata, :resource_type, index: true
      rename_column :metadata, :genre_str, :genre
      rename_column :metadata, :resource_type_str, :resource_type

      puts "Removing lookup tables..."
      drop_table :genres
      drop_table :resource_types
   end
end
