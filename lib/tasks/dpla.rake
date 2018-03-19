namespace :dpla do
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
         max_cnt = 2
         colls +=1
         ts0 = Time.now
         total += generate_collection_qdc(m.id, qdc_tpl, max_cnt)
         dur = (Time.now-ts0).round(2)
         total_time += dur
         puts "===> DONE. Elapsed seconds: #{dur}"
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
      Metadata.find(metadata_id).children.each do |meta|
         next if !meta.dpla
         puts "Process #{meta.id}:#{meta.pid}..."

         PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl)

         meta.update(qdc_generated_at: DateTime.now)

         cnt += 1
         if max_cnt > -1 && cnt == max_cnt
            puts "Stopping after #{cnt}"
            break
         end
      end
      return cnt
   end
end
