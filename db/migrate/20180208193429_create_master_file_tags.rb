class CreateMasterFileTags < ActiveRecord::Migration[5.1]
   def change
      create_table :tags do |t|
         t.string :tag
      end

      create_table :master_file_tags do |t|
         t.references :master_file, index: true
         t.references :tag, index: true
      end
   end
end
