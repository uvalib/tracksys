namespace :migrate do
   desc "Migrate XML metadata"
   task :xml  => :environment do
      puts "Creating XML Metadata records from bibls"
       Bibl.find_each do |bibl|
         if !bibl.desc_metadata.blank? && bibl.desc_metadata.include?("xml version")
            xml = XmlMetadata.create(
               schema: "mods", title: bibl.title, content: bibl.desc_metadata,
               is_approved: bibl.is_approved, is_personal_item: bibl.is_personal_item,
               resource_type: bibl.resource_type, genre: bibl.genre, pid: bibl.pid,
               is_in_catalog: bibl.is_in_catalog, exemplar: bibl.exemplar,
               discoverability: bibl.discoverability, date_dl_ingest: bibl.date_dl_ingest,
               date_dl_update: bibl.date_dl_update, units_count: bibl.units_count,
               collection_facet: bibl.collection_facet, creator_name: bibl.creator_name
            )
            Unit.where(bibl_id: bibl.id).each do |unit|
               unit.metadata = xml
               unit.bibl = nil
               unit.save!
            end

            bibl.destroy
         end
       end
   end
end
