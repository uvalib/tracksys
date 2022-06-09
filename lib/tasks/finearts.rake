namespace :finearts do
   desc "import finearts masterfiles from CSV/Archive"
   task :import  => :environment do
      arch_csv = File.join(Rails.root, "data", "ARCH_List.csv")
      processed = []
      progress_file = File.join(Rails.root, "tmp", "arch_processed.txt")
      if File.exists? progress_file
         file = File.open(progress_file)
         progress_str = file.read
         processed = progress_str.split(",")
         file.close
      end
      cnt = 0
      already_done = 0
      missing_order = 0
      bad_units = 0
      max_processed = 5
      CSV.foreach(arch_csv, headers: true) do |row|
         order_id = row[0]
         from_dir = row[2]
         puts "import #{from_dir} to order #{order_id}"
         if processed.include? order_id
            puts "     order has already been processed"
            already_done +=1
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
         begin
            url = "#{Settings.jobs_url}/units/#{unit_id}/import"
            payload =  { from: "archive", target: from_dir}
            puts "     url #{url}, payload: #{payload.to_json}"
            RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, timeout: nil)
            processed << order_id
            cnt += 1
         rescue => exception
            puts "ERROR: import failed - #{exception}"
            break
         end

         if cnt >= max_processed
            break
         end

      end

      if processed.length > 0
         file = File.open(progress_file, File::WRONLY|File::TRUNC|File::CREAT)
         file.write(processed.join(","))
         file.close
      end

      puts "DONE. Imported #{cnt+already_done} ARCH units. #{missing_order} missing orders, #{bad_units} orders with unit problems"
   end
end