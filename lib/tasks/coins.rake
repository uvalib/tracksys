namespace :coins do
   SITE_ROOT = "http://coins.lib.virginia.edu/"

   desc "Setup for ingest; create order,unit and metadata"
   task :setup => :environment do
      customer = Customer.find_by(email: "lf6f@virginia.edu")
      title = "Fralin Numismatic Collection"
      order = Order.find_by(order_title: title)
      if order.nil?
         puts "Creating order"
         today = DateTime.now
         order = Order.create(order_title: title, order_status: "approved",
            staff_notes: "Order to ingest Fralin coins collection",
            date_request_submitted: today, date_due: "2017-12-31",
            customer: customer, is_approved: true, date_order_approved: today
         )
      else
         puts "Using existing order #{order.id}"
      end

      if order.units.count == 0
         xml = XmlMetadata.find_by(title: title)
         if xml.nil?
            metadata  = '<?xml version="1.0" encoding="UTF-8"?>\n'
            metadata << '<mods xmlns="http://www.loc.gov/mods/v3"\n'
            metadata << '    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"\n'
            metadata << '    xmlns:mods="http://www.loc.gov/mods/v3"\n'
            metadata << '    xsi:schemaLocation="http://www.loc.gov/mods/v3\n'
            metadata << '    http://www.loc.gov/standards/mods/v3/mods-3-3.xsd">\n'
            metadata << '   <titleInfo>\n'
            metadata << "      <title>#{title}</title>\n"
            metadata << '   </titleInfo>\n'
            metadata << '</mods>'
            puts "Create XML metadata for collection"
            xml = XmlMetadata.create(title: title, is_approved: true, discoverability: false,
               availability_policy_id: 1, dpla: false, resource_type_id: 7, ocr_hint_id: 2,
               desc_metadata: metadata, use_right_id: 2
            )
         else
            puts "Using existing collection XML metadata #{xml.id}"
         end

         unit = Unit.create(metadata: xml, unit_status: "approved", order: order,
            intended_use_id: 110, staff_notes: "Unit for #{title}")
         puts "Created unit. Setup is complete."
      else
         puts "Order already has a unit. Setup is complete"
      end
   end

   desc "Ingest coins XML and scrape JPG from website"
   task :ingest  => :environment do
      base_dir = ENV['dir']
   end
end
