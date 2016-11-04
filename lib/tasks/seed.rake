namespace :seed do

   desc "Seed collection facets"
   task :facets => :environment do
      CollectionFacet.create(name: "McGregor Grant Collection" )
   end
end
