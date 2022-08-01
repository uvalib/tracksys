namespace :finearts do
   desc "import BATCH of finearts masterfiles from params"
   task :batch  => :environment do
      batch = [
         {order: 7824, dir: "20141007ARCH"},
         {order: 7825, dir: "20141008ARCH"},
         {order: 7826, dir: "20141009ARCH"},
         {order: 8067, dir: "20141204ARCH"},
         {order: 8068, dir: "20150119ARCH"},
         {order: 8086, dir: "20150207ARCH"},
         {order: 8087, dir: "20150208ARCH"},
         {order: 8088, dir: "20150218ARCH"},
         {order: 8232, dir: "20150441ARCH"},
         {order: 8255, dir: "20150435ARCH"},
         {order: 8360, dir: "20150223ARCH"},
         {order: 8500, dir: "20150501ARCH"},
         {order: 8611, dir: "20150501ARCH"},
         {order: 8849, dir: "20151107ARCH"},
         {order: 9457, dir: "20160915ARCH"},
      ]

      batch.each do |data|
         order_id = data[:order]
         from_dir = data[:dir]
         puts "import #{from_dir} to order #{order_id}"
         o = Order.find(order_id)
         if o.nil?
            abort "ERROR: order #{order_id} not found"
         end
         if o.units.length != 1
            abort "ERROR: order #{order_id} has #{o.units.length} units"
         end

         begin
            unit_id = o.units.first.id
            url = "#{Settings.jobs_url}/units/#{unit_id}/import"
            payload =  { from: "archive", target: from_dir}
            puts "     url #{url}, payload: #{payload.to_json}"
            RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, timeout: nil)
            puts "DONE"
         rescue => exception
            puts "ERROR: import failed - #{exception}"
            break
         end
      end
   end

   desc "import ORDER of finearts masterfiles from params"
   task :order  => :environment do
      order_id = ENV['order']
      from_dir = ENV['dir']

      puts "import #{from_dir} to order #{order_id}"
      o = Order.find(order_id)
      if o.nil?
         abort "ERROR: order #{order_id} not found"
      end
      if o.units.length != 1
         abort "ERROR: order #{order_id} has #{o.units.length} units"
      end

      begin
         unit_id = o.units.first.id
         url = "#{Settings.jobs_url}/units/#{unit_id}/import"
         payload =  { from: "archive", target: from_dir}
         puts "     url #{url}, payload: #{payload.to_json}"
         RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, timeout: nil)
         puts "DONE"
      rescue => exception
         puts "ERROR: import failed - #{exception}"
         break
      end
   end

   desc "import UNIT of finearts masterfiles from params"
   task :unit  => :environment do
      unit_id = ENV['unit']
      from_dir = ENV['dir']
      begin
         url = "#{Settings.jobs_url}/units/#{unit_id}/import"
         payload =  { from: "archive", target: from_dir}
         puts "     url #{url}, payload: #{payload.to_json}"
         RestClient::Request.execute(method: :post, url: url, payload: payload.to_json, timeout: nil)
         puts "DONE"
      rescue => exception
         puts "ERROR: import failed - #{exception}"
         break
      end
   end

   desc "import finearts masterfiles from CSV/Archive"
   task :import  => :environment do
      arch_csv = File.join(Rails.root, "data", "ARCH_List.csv")
      processed = []
      missing = []
      skip = []
      progress_file = File.join(Rails.root, "tmp", "arch_processed.txt")
      if File.exists? progress_file
         file = File.open(progress_file)
         raw = file.read
         processed = raw.split(",")
         file.close
      end
      missing_file = File.join(Rails.root, "tmp", "arch_missing.txt")
      if File.exists? missing_file
         file = File.open(missing_file)
         raw = file.read
         missing = raw.split(",")
         file.close
      end
      skip_file = File.join(Rails.root, "tmp", "arch_skip.txt")
      if File.exists? skip_file
         file = File.open(skip_file)
         raw = file.read
         skip = raw.split(",")
         file.close
      end
      cnt = 0
      missing_order = 0
      bad_units = 0
      max_processed = 15 ######## PROCESSING CHUNK SIZE
      CSV.foreach(arch_csv, headers: true) do |row|
         order_id = row[0]
         from_dir = row[2]
         puts "import #{from_dir} to order #{order_id}"
         if skip.include? order_id
            puts "     is on the skip list"
            next
         end
         if processed.include? order_id
            puts "     order has already been processed"
            next
         end
         if missing.include? order_id
            puts "     order has already been marked as missing"
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

         begin
            puts "     check if #{from_dir} exists"
            resp = RestClient.get "#{Settings.jobs_url}/archive/exist?dir=#{from_dir}"
            puts "     #{resp.body}"
         rescue => exception
            puts "     ERROR: #{from_dir} not found"
            missing << order_id
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
      if missing.length > 0
         file = File.open(missing_file, File::WRONLY|File::TRUNC|File::CREAT)
         file.write(missing.join(","))
         file.close
      end

      puts "DONE. Imported #{processed.length} units"
      puts "     #{missing_order} missing orders, #{missing.length} missing archive, #{bad_units} orders with unit problems"
      puts "     #{skip.length} skipped"
   end
end