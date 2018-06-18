class MoveExemplarToMasterFiles < ActiveRecord::Migration[5.2]
   def up
      puts "Adding exemplar flag to master file..."
      add_column :master_files, :exemplar, :boolean, default: false

      puts "Migrating existing metadata exemplar settings to master files..."
      cnt = 0
      Metadata.where("exemplar <> ''").find_each do |meta|
         mf = MasterFile.find_by(filename: meta.exemplar)
         if mf.nil?
            puts ""
            puts "WARNING: exemplar #{meta.exemplar} for metadata #{meta.id} does not exist. Skipping!"
         else
            mf.update!(exemplar: true)
         end
         cnt += 1
         if cnt > 100
            print "."
            cnt = 0
         end
      end

      puts "Drop exemplar from metadata..."
      remove_column :metadata, :exemplar, :string
      puts "DONE"
   end

   def down
      puts "Adding exemplar to metadata..."
      add_column :metadata, :exemplar, :string

      puts "Migrating metadata from master files to metadata..."
      MasterFile.where(exemplar: true).find_each do |mf|
         MasterFile.find_by(filename: meta.exemplar).update!(exemplar: true)
         mf.metadata.update!(exemplar: mf.filename)
      end

      puts "Drop exemplar from master file..."
      remove_column :master_file, :exemplar, :boolean
      puts "DONE"
   end
end
