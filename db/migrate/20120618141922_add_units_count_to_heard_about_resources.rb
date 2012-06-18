class AddUnitsCountToHeardAboutResources < ActiveRecord::Migration
  def up
    add_column :heard_about_resources, :units_count, :integer
    say "Updating agency.orders_count"
    HeardAboutResource.find(:all).each {|h|
      HeardAboutResource.update_counters h.id, :units_count => h.units.count
    }
  end
  
  def down
    remove_column :heard_about_resources, :units_count
  end
end
