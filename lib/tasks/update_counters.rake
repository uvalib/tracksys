namespace :counters do
  desc "Update units_count on all Bibl records."
  task :update_bibls => :environment do
    Bibl.find_in_batches do |batch|
      batch.each {|bibl|
        Bibl.reset_counters(bibl.id, :units)
      }
    end
  end

  desc "Update units_count and master_files_count on all Order records."  
  task :update_orders => :environment do
    Order.find_in_batches do |batch|
      batch.each {|order|
        Order.reset_counters(order.id, :units)
        Order.reset_counters(order.id, :master_files)
      }
    end
  end
  
  desc "Update master_files_count for all Component records."
  task :update_components => :environment do
  	Component.find_in_batches do |batch|
  		batch.each { |component|
  			Component.reset_counters( component.id, :master_files )
  		}
  	end
  end

  desc "Update counts for all: components, bibls, & orders."
  task :update_all => [ :update_components, :update_bibls, :update_orders ] 

  
end
