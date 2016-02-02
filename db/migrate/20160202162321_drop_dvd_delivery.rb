class DropDvdDelivery < ActiveRecord::Migration
  def up
     remove_foreign_key :orders, :dvd_delivery_location
     remove_column :orders, :dvd_delivery_location_id
     drop_table :dvd_delivery_locations
  end

  def down
     create_table :dvd_delivery_locations do |t|
        t.string :name
        t.string :email_desc
     end
     add_column :orders, :dvd_delivery_location_id, :integer
  end
end
