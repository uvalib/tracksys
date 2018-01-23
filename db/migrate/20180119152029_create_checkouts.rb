class CreateCheckouts < ActiveRecord::Migration[5.1]
   def up
      puts "Create checkouts table..."
      create_table :checkouts do |t|
         t.belongs_to :metadata, index: true
         t.date  :checkout_date;
         t.date  :return_date;
      end

      puts "Migrate unit checkouts to metadata checkouts..."
      q = "date_materials_received is not null and metadata.type='SirsiMetadata'"
      Unit.joins(:metadata).where(q).order("date_materials_received asc").find_each do |u|
         print "."
         if u.date_materials_returned.nil?
            if u.date_materials_received.strftime("%F") < "2016"
               # prior to 2016, assume item was checked in 3 months later
               Checkout.create(metadata_id: u.metadata_id, checkout_date: u.date_materials_received, return_date: u.date_materials_received+3.months)
            else
               # from 2016 on, leave item checked out
               Checkout.create(metadata_id: u.metadata_id, checkout_date: u.date_materials_received)
            end
         else
            Checkout.create(metadata_id: u.metadata_id, checkout_date: u.date_materials_received, return_date: u.date_materials_returned)
         end
      end
   end

   def down
      drop_table :checkouts
   end
end
