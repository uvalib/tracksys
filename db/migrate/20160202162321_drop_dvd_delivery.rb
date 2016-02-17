class DropDvdDelivery < ActiveRecord::Migration
  def up
     if ActiveRecord::Base.connection.table_exists? 'dvd_delivery_locations'
        remove_foreign_key :orders, :dvd_delivery_location
        remove_column :orders, :dvd_delivery_location_id
        drop_table :dvd_delivery_locations
     end
  end

  def down
     # not reversable
  end

end
