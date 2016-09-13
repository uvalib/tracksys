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
end
