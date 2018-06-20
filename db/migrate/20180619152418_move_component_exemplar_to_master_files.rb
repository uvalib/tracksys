class MoveComponentExemplarToMasterFiles < ActiveRecord::Migration[5.2]
   def up
      puts "Migrating existing component exemplar settings to master files..."

      # first, find all of the exemplar masterfiles that are associated with a component.
      # save these component IDs and exclude from the update below. Reason;
      # the prior exemplar setting (from a metadata migration) seem to be
      # a better choice (most of the component exemplars are simply the first page)
      q = "select c.id from master_files mf inner join components c on c.id = component_id where mf.exemplar=1"
      existing = Component.find_by_sql(q).pluck(:id).to_a

      cnt = 0
      Component.where("exemplar <> ''").find_each do |c|
         # Skip components that have masterfiles already tagged with exemplar info
         next if existing.include? c.id

         # look up the master file exemplar by filename and flag it as an exemplar
         mf = MasterFile.find_by(filename: c.exemplar)
         if mf.nil?
            puts ""
            puts "WARNING: exemplar #{c.exemplar} for component #{c.id} does not exist. Skipping!"
         elsif mf.is_clone?
            puts ""
            puts "WARNING: exemplar #{c.exemplar} for component #{c.id} is a clone. This is invalid. Skipping!"
         else
            mf.update!(exemplar: true)
         end

         cnt += 1
         if cnt > 100
            print "."
            cnt = 0
         end
      end

      puts "Drop exemplar from component..."
      remove_column :components, :exemplar, :string
      puts "DONE"
   end

   def down
      puts "Adding exemplar to component..."
      add_column :components, :exemplar, :string

      puts "Migrating metadata from master files to component..."
      MasterFile.where("exemplar = 1 and component_id is not null").find_each do |mf|
         mf.component.update!(exemplar: mf.filename)
      end

      puts "DONE"
   end
end
