namespace :counters do

   desc "Update units_count and master_files_count on all Order records."
   task :update_orders => :environment do
      Order.find_in_batches do |batch|
         batch.each do |order|
            Order.reset_counters(order.id, :units)
            Order.reset_counters(order.id, :master_files)
         end
      end
   end

   desc "Update master_files_count for all Component records."
   task :update_components => :environment do
      Component.find_in_batches do |batch|
         batch.each do  |component|
            Component.reset_counters( component.id, :master_files )
         end
      end
   end

   desc "Update counts for all: components, bibls, & orders."
   task :update_all => [ :update_components, :update_bibls, :update_orders ]

   desc "Update masterfile and metadata count for use right"
   task :update_use_right => :environment do
      UseRight.all.each do |ur|
         UseRight.reset_counters( ur.id, :metadata )
      end
   end

   desc "Update masterfile and metadata count for indexing scenarios"
   task :update_indexing_scenario => :environment do
      IndexingScenario.all.each do |is|
         IndexingScenario.reset_counters( is.id, :metadata )
      end
   end
end
