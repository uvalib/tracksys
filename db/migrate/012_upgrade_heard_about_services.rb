class UpgradeHeardAboutServices < ActiveRecord::Migration

  def change
    add_column :heard_about_services, :customers_count, :integer, :default => 0
  end
  
end
