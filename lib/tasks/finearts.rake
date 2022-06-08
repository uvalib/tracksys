namespace :finearts do
   desc "import finearts masterfiles from CSV/Archive"
   task :import  => :environment do
      arch_csv = File.join(Rails.root, "data", "ARCH_List.csv")
      processed = []
      progress_file = File.join(Rails.root, "tmp", "arch_processed.csv")
      if File.exists? progress_file
         file = File.open(progress_file)
         progress_str = file.read
         processed = progress_str.split(",")
         file.close
      end
      cnt = 0
      missing_order = 0
      bad_units = 0
      CSV.foreach(arch_csv, headers: true) do |row|
         order_id = row[0]
         from_dir = row[2]
         puts "import #{from_dir} to order #{order_id}"
         if processed.include? order_id
            puts "     order has already been processed"
            next
         end
         o = Order.find(order_id)
         if o.nil?
            puts "ERROR: order #{order_id} not found"
            missing_order += 1
            next
         end
         if o.units.length != 1
            puts "ERROR: order #{order_id} has #{o.units.length} units"
            bad_units += 1
            next
         end

         unit_id = o.units.first.id
         puts "     unit #{unit_id}"
         resp = Job.submit("/units/#{unit_id}/import", { from: "archive", target: from_dir} )
         if resp.success?
            processed << order_id
            cnt += 1
         else
            puts "ERROR: import failed - #{resp.message}"
            break
         end

         break

      end

      if processed.length > 0
         file = File.open(progress_file, File::WRONLY|File::TRUNC|File::CREAT)
         file.write(processed.join(","))
         file.close
      end

      puts "DONE. Imported #{cnt} ARCH units. #{missing_order} missing orders, #{bad_units} orders with unit problems"
   end
end