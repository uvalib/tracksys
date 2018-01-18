namespace :validate do
   desc "Generate report of SIRSI metadata without units"
   task :metadata  => :environment do
      # NOTE this only makes sense for Sirsi as XML is
      # directly associated with a master file not a unit
      puts "ID,BARCODE,TITLE"
      q = "SELECT m.id,barcode,title from metadata m "
      q << " LEFT JOIN units u ON u.metadata_id = m.id "
      q << " WHERE metadata_id IS NULL and m.type='SirsiMetadata' group by m.id"
      SirsiMetadata.connection.execute(q).each do |r|
         puts "#{r[0]},#{r[1]},\"#{r[2].gsub(/\"/, "'")}\""
      end
   end

   desc "Generate a report of SirsiMetadata records that have a catalog key but no call number"
   task :call_number  => :environment do
      puts "ID,BARCODE,CATALOG_KEY,TITLE"
      q = "call_number is not null and call_number <> '' and (catalog_key = '' or catalog_key is null)"
      SirsiMetadata.where(q).each do |r|
         title = r.title.strip
         title.gsub! /\n/, " "
         title.gsub! /\r/, ""
         title.gsub! /\"/, "'"
         puts "#{r.id},#{r.barcode},#{r.call_number},\"#{title}\""
      end
   end

   desc "Generate report of customers without orders"
   task :customers  => :environment do
      puts "ID,LAST_NAME,FIRST_NAME"
      q = "SELECT c.id,last_name,first_name from customers c"
      q << " LEFT JOIN orders o ON o.customer_id = c.id"
      q << " WHERE customer_id IS NULL"
      Customer.connection.execute(q).each do |r|
         puts "#{r[0]},\"#{r[1]}\",\"#{r[2]}\""
      end
   end

   desc "Generate report of orders without units"
   task :orders  => :environment do
      puts "ID,TITLE,STATUS,DUE"
      q = "SELECT o.id,order_title,order_status,date_due from orders o"
      q << " LEFT JOIN units u ON o.id = u.order_id"
      q << " WHERE order_id IS NULL"
      Customer.connection.execute(q).each do |r|
         puts "#{r[0]},\"#{r[1]}\",#{r[2]},#{r[3]}"
      end
   end

   desc "Generate report of units without master files"
   task :units  => :environment do
      puts "ID,ORDER_TITLE,ORDER_STATUS,UNIT_STATUS,DATE"
      q = "SELECT u.id,order_title,order_status,unit_status,u.created_at from units u"
      q << " LEFT JOIN master_files m ON m.unit_id = u.id"
      q << " inner join orders o on o.id = u.order_id"
      q << " WHERE unit_id IS NULL"
      Customer.connection.execute(q).each do |r|
         puts "#{r[0]},\"#{r[1]}\",#{r[2]},#{r[3]},#{r[4].strftime("%F")}"
      end
   end
end
