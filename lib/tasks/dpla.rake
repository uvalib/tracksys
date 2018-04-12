namespace :dpla do
   desc "Visual history cleanup"
   task :clean_visual_history  => :environment do
      q = "parent_metadata_id = 3009 and not ( "
      q << " desc_metadata like '%namePart>Thompson, Ralph R%' "
      q << " or desc_metadata like '%namePart>Skinner, David M%' "
      q << " or desc_metadata like '%namePart>University of Virginia. News Office%' "
      q << " or desc_metadata like \"%namePart>Holsinger's Studio (Charlottesville, Va.)%\")"
      puts "Removing DPLA flag from Visual History records..."
      Metadata.where(q).update_all(dpla: 0, qdc_generated_at: nil)

      puts "Setting rights CNE for skinner, thompson and UVA news.."
      q = "parent_metadata_id = 3009 and ( "
      q << " desc_metadata like '%namePart>Thompson, Ralph R%' "
      q << " or desc_metadata like '%namePart>Skinner, David M%' "
      q << " or desc_metadata like '%namePart>University of Virginia. News Office%') "
      Metadata.where(q).update_all(use_right_id: 1)

      puts "Setting rights UND for Holsinger.."
      q = "parent_metadata_id = 3009 and desc_metadata like \"%namePart>Holsinger's Studio (Charlottesville, Va.)%\""
      Metadata.where(q).update_all(use_right_id: 11)
   end

   desc "Set use rights"
   task :update_rights  => :environment do
      puts "Set text collection to NoC-US..."
      Metadata.where(parent_metadata_id: 15784).update_all(use_right_id: 10)

      puts "Set Frances Benjamin Johnston to NoC-US..."
      Metadata.where(parent_metadata_id: 16315).update_all(use_right_id: 10)

      puts "Set Holsinger (negatives from c'ville photo studio) to UND..."
      Metadata.where(parent_metadata_id: 3002).update_all(use_right_id: 11)

      # puts "Set Jackson Davis to UND..."
      # Metadata.where(parent_metadata_id: 3109).update_all(use_right_id: 11)

      puts "Set Online Artifacts to InC-NC..."
      Metadata.where(parent_metadata_id: 16585).update_all(use_right_id: 5)

      puts "Set Vanity Fair to NoC-US..."
      Metadata.where(parent_metadata_id: 6405).update_all(use_right_id: 10)

      puts "Set Printing Services to CNE..."
      ps_ids = [
         18146, 18148, 18235, 18236, 18303, 18304, 18532, 18533, 18534, 18535, 18536, 18537,
         18538, 18539, 18540, 18541, 18559, 18560, 18561, 18562, 18563, 18564, 18565, 18566, 18567
      ]
      ps_ids.each do |pd_id|
         Metadata.where(parent_metadata_id: pd_id).update_all(use_right_id: 1)
      end
   end

   desc "add University of Virginia Printing Services"
   task :add_printing_service_images  => :environment do
      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      cnt = 0
      Metadata.where("title like ?", "University of Virginia Printing Services%").each do |m|
         if m.dpla == false && m.in_dl?
            puts "*** #{m.id} - #{m.title} #{m.call_number} flag for DPLA"
            m.update(dpla: true)
         end
         if m.in_dl?
            puts "Generate QDC for collection #{m.id}:#{m.title} - #{m.call_number}"
            cnt += generate_collection_qdc(m.id, qdc_tpl, -1)
         end
      end
      puts "DONE. Generated #{cnt} QDC records"
   end

   desc "Remove untitied metadata form QDC repo"
   task :remove_untitled  => :environment do
      cnt = 0
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      Metadata.where(title: "untitled").each do |m|
         puts "#{m.id}: is untitled"
         pid_path = QDC.relative_pid_path(m.pid)
         del_path = File.join(qdc_dir, pid_path, "#{m.pid}.xml")
         puts "   remove #{del_path}"
         m.update(dpla: false, qdc_generated_at: nil)
         if File.exist?(del_path)
            File.delete(del_path)
         else
            puts "ERROR: Not found #{del_path}"
         end
         cnt +=1
      end
      puts "Removed #{cnt} untitled records"
   end

   desc "Fix a batch of bad pids"
   task :fix  => :environment do
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      File.open(File.join(Rails.root, "data/qdcfixpids.txt"), "r").each_line do |pid|
         puts "Generate QDC for #{pid.strip}"
         begin
            meta = Metadata.find_by(pid: pid.strip)
            PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl)
            meta.update(qdc_generated_at: DateTime.now)
         rescue Exception=>e
            puts "ERROR: Unable to generate QDC for this record; skipping it. Cause: #{e}"
            puts e.backtrace
            puts "==============================================================================="
         end
      end
   end

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
