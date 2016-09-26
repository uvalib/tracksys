namespace :migrate do
   desc "Migrate bibls into sirsi and xml metadata"
   task :xml  => :environment do
       puts "Creating XML Metadata records from metadata"
       Metadata.find_each do |metadata|
         if !metadata.desc_metadata.blank? && metadata.desc_metadata.include?("xml version")
            metadata.update(type: "XmlMetadata", discoverability: false)
         end
       end
   end

   task :unit_metadata_to_mf  => :environment do
      puts "Flagging all masterfiles wit metadata from unit"
      Unit.where('metadata_id is not null').order(id: :asc).find_each do |u|
         next if u.master_files.size == 0
         sql = "update master_files set metadata_id=#{u.metadata_id} where master_files.unit_id=#{u.id}"
         ActiveRecord::Base.connection.execute(sql)
      end
   end

   task :mf_desc_metadata  => :environment do
      puts "Creating XML Metadata records from masterfile desc_metadata"
      MasterFile.where("desc_metadata <> '' and desc_metadata is not null").find_each do |mf|
         title = mf.title
         xml = Nokogiri::XML( mf.desc_metadata )
         title_node = xml.xpath("//mods:titleInfo/mods:title").first
         if !title_node.nil?
            title = title_node.text.strip
         end
         creator = nil
         creator_node = xml.xpath("//mods:name/mods:namePart").first
         creator = creator_node.text if !creator_node.nil?
         metadata = Metadata.create!(type: "XmlMetadata", title: title, is_approved: 1,
            discoverability: mf.discoverability, indexing_scenario_id: mf.indexing_scenario_id,
            desc_metadata: mf.desc_metadata, creator_name: creator, exemplar: mf.filename )
         puts "Created metadata #{metadata.id} title: #{metadata.title}"
         mf.update(metadata_id: metadata.id)
      end
   end
end
