namespace :migrate do
   desc "Migrate bibls into sirsi and xml metadata"
   task :xml  => :environment do
       puts "Creating XML Metadata records from bibls"
       SirsiMetadata.find_each do |metadata|
         if !metadata.desc_metadata.blank? && metadata.desc_metadata.include?("xml version")
            puts "Metadata #{metadata.id} is XML"
            # This is a bibl record that has desc_metadata. Convert it into xml_metadata....
            xml = XmlMetadata.create(
               schema: "mods", title: metadata.title, content: metadata.desc_metadata,
               is_approved: metadata.is_approved, is_personal_item: metadata.is_personal_item,
               resource_type: metadata.resource_type, genre: metadata.genre, pid: metadata.pid,
               is_in_catalog: metadata.is_in_catalog, exemplar: metadata.exemplar,
               discoverability: metadata.discoverability, date_dl_ingest: metadata.date_dl_ingest,
               date_dl_update: metadata.date_dl_update, units_count: metadata.units_count,
               collection_facet: metadata.collection_facet, creator_name: metadata.creator_name
            )
            puts "   created new XML Metadata record #{xml.id} : #{xml.pid}"

            # Update related units to polymorphically point to the new metadata
            metadata.units.each do |unit|
               puts "   Updating unit #{unit.id}"
               unit.metadata = xml
               unit.save!
            end

            # Original record is no longer necessary
            puts "   removing old metadata record"
            if !metadata.destroy
               puts " *** Unable to destroy sirsi copy of XML metadata: #{metadata.id}"
            end
         end
       end
   end
end
