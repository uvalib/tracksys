class UseRightFixes < ActiveRecord::Migration[5.1]
   def up
      puts "Adding use rights fields..."
      add_column :metadata, :use_right_rationale, :string
      add_column :metadata, :creator_death_date, :integer

      puts "Migrate existing creator death date..."
      q = 'master_files.creator_death_date is not null and master_files.creator_death_date <> ""'
      Metadata.joins(:master_files).where(q).distinct.each do |m|
         dd= ""
         skip = false
         m.master_files.each do |mf|
            next if mf.creator_death_date.blank?
            next if mf.creator_death_date == "unknown"
            next if mf.creator_death_date.include?(",") ||  mf.creator_death_date.include?("and")
            if dd.blank?
               dd = mf.creator_death_date
            else
               if mf.creator_death_date != dd
                  skip = true
                  break
               end
            end
         end
         if skip == false
            year = dd.gsub(/ca\./, "").strip.to_i
            puts "Setting creator_death_date on Metadata #{m.id} to #{year}"
            m.update(creator_death_date: year)
         end
      end

      puts "Remove master file creator death date..."
      remove_column :master_files, :creator_death_date, :string

      puts "DONE"
   end

   def down
      puts "Adding master file creator death date..."
      add_column :master_files, :creator_death_date, :string

      puts "Remove new metadata fields..."
      remove_column :metadata, :use_right_rationale, :string
      remove_column :metadata, :creator_death_date, :integer

      puts "DONE"
   end
end
