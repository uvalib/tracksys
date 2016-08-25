#
# ONLY WORKS BEFORE THE MIGRATIONS TO CONVERT BIBL TO METDATA ARE RUN
#
namespace :cleanup do
   desc "** RUN BEFORE MIGRATE ** Purge unused bibls"
   task :unused_bibls  => :environment do
      puts "Getting unused bibl records"
      bibls = Bibl.joins("left join units on units.bibl_id=bibls.id").where("units.bibl_id is null")
      puts "found #{bibls.count} unused bibls. Deleting..."
      bibls.destroy_all
      puts "done"
   end

   desc "** RUN BEFORE MIGRATE ** Migrate bibls that are neither sirsi nor xml into mods XML"
   task :to_mods  => :environment do
      id = ENV['id']
      if !id.nil?
         puts "Creating MODS XML Metadata record for bibl #{id}"
         b = Bibl.find(id.to_i)
         mods_xml = ApplicationController.new.render_to_string(
            :template => 'template/mods.xml',
            :locals => { :bibl => b }
         )
         b.desc_metadata = mods_xml
         b.save!
      else
         puts "Creating MODS XML Metadata records from available info"
         sql = "(catalog_key is null or catalog_key='test') and desc_metadata is null and units_count > 0"
         Bibl.where(sql).each do |b|
            if !b.desc_metadata.blank?
               puts "** ERROR ** Skipping bibl #{b.id} with non-null desc_metadata"
               next
            end
            mods_xml = ApplicationController.new.render_to_string(
               :template => 'template/mods.xml',
               :locals => { :bibl => b }
            )
            b.desc_metadata = mods_xml
            b.save!
            puts "Generated MODS for #{b.id}: #{b.title}"
         end
      end
   end
end
