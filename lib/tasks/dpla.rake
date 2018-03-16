namespace :dpla do
   desc "Generate DPLA QDC for all collection records"
   task :generate_all  => :environment do
      q = "select distinct mp.id, mp.title from metadata mc"
      q << " inner join metadata mp on mc.parent_metadata_id = mp.id"
      q << " where mc.parent_metadata_id <> '' and mp.dpla = 1 and mp.date_dl_ingest is not null"
      q << " order by mp.id asc"
      Metadata.find_by_sql(q).each do |m|
         puts "===> Processing #{m.id}: #{m.title}"
         ENV['id'] = m.id.to_s
       ENV['cnt'] = "1"
         Rake::Task['dpla:generate'].execute
      end
   end

   desc "Generate DPLA QDC for a single collection record"
   task generate: :environment do
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      metadata_id = ENV['id']
      abort("ID is required!") if metadata_id.nil?

      max_cnt = ENV['cnt']
      if max_cnt.nil?
         max_cnt = -1
      else
         puts "Test: limit generation to #{max_cnt} records"
         max_cnt = max_cnt.to_i
      end

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      cnt = 0
      Metadata.find(metadata_id).children.each do |meta|
         next if !meta.dpla
         puts "Process #{meta.id}:#{meta.pid}..."

         PublishQDC.generate_qdc(meta,qdc_dir, qdc_tpl)

         cnt += 1
         if max_cnt > -1 && cnt == max_cnt
            puts "Stopping after #{cnt}"
            break
         end
      end
   end
end
