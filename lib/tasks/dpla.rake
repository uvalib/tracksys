namespace :dpla do
   desc "Generate DPLA QDC a single record"
   task :generate  => :environment do
      id = ENV['id']
      abort("ID is required") if id.nil?

      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      begin
         meta = Metadata.find(id)
         PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl)
         meta.update(qdc_generated_at: DateTime.now)
      rescue Exception=>e
         puts "ERROR: Unable to generate QDC for this record; skipping it. Cause: #{e}"
         puts e.backtrace
         puts "==============================================================================="
      end

   end

   desc "Generate DPLA QDC for all collection records"
   task :generate_all  => :environment do
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      q = "select distinct mp.id, mp.title from metadata mc"
      q << " inner join metadata mp on mc.parent_metadata_id = mp.id"
      q << " where mc.parent_metadata_id <> '' and mp.dpla = 1 and mp.date_dl_ingest is not null"
      q << " order by mp.id asc"
      total = 0
      colls = 0
      total_time = 0
      Metadata.find_by_sql(q).each do |m|
         puts "===> Processing collection #{m.id}: #{m.title}"
         #max_cnt = 2
         max_cnt = -1
         colls +=1
         ts0 = Time.now
         total += generate_collection_qdc(m.id, qdc_tpl, max_cnt)
         dur = (Time.now-ts0).round(2)
         total_time += dur
         puts "===> DONE. Elapsed seconds: #{dur}"
      end

      puts "Generate QDC for metadata that is not part of a collecion..."
      # Now get stand-along DPLA flagged metadata and generate the records
      q = "select distinct m.id from metadata m"
      q << " inner join units u on u.metadata_id = m.id"
      q << " where parent_metadata_id = '' and dpla = 1 and date_dl_ingest is not null"
      q << " and u.include_in_dl=1 and discoverability=1"
      Metadata.find_by_sql(q).each do |resp|
         meta = Metadata.find(resp.id)
         puts "Process #{meta.id}: #{meta.pid}..."
         begin
            ts0 = Time.now
            PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl)
            meta.update(qdc_generated_at: DateTime.now)
            dur = (Time.now-ts0).round(2)
            total_time += dur
            total += 1
         rescue Exception=>e
            puts "ERROR: Unable to generate QDC for this record; skipping it. Cause: #{e}"
            puts e.backtrace
            puts "==============================================================================="
         end
      end

      puts
      puts "FINISHED! Generated #{total} QDC records from #{colls} collections in #{(total_time/60).round(3)} minutes"
   end

   def generate_collection_qdc(metadata_id, qdc_tpl, max_cnt=-1)
      if max_cnt > -1
         puts "Test: limit generation to #{max_cnt} records"
         max_cnt = max_cnt.to_i
      end

      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      cnt = 0
      Metadata.find(metadata_id).children.find_each do |meta|
         next if !meta.dpla || !meta.discoverability || meta.date_dl_ingest.blank?
         next if meta.units.count == 1 && meta.units.first.unit_status == "canceled"
         puts "Process #{meta.id}:#{meta.pid}..."

         begin
            PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl)
            meta.update(qdc_generated_at: DateTime.now)
            cnt += 1
            if max_cnt > -1 && cnt == max_cnt
               puts "Stopping after #{cnt}"
               break
            end
         rescue Exception=>e
            puts "ERROR: Unable to generate QDC for this record; skipping it. Cause: #{e}"
            puts e.backtrace
            puts "==============================================================================="
         end
      end
      return cnt
   end
end
