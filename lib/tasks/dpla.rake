namespace :dpla do
   desc "Visual history cleanup"
   task :clean_visual_history  => :environment do
      # q = "parent_metadata_id = 3009 and not ( "
      # q << " desc_metadata like '%namePart>Thompson, Ralph R%' "
      # q << " or desc_metadata like '%namePart>Skinner, David M%' "
      # q << " or desc_metadata like '%namePart>University of Virginia. News Office%' "
      # q << " or desc_metadata like \"%namePart>Holsinger's Studio (Charlottesville, Va.)%\")"
      # puts "Removing DPLA flag from Visual History records..."
      # Metadata.where(q).update_all(dpla: 0, qdc_generated_at: nil)

      # puts "Setting rights CNE for skinner, thompson and UVA news.."
      # q = "parent_metadata_id = 3009 and ( "
      # q << " desc_metadata like '%namePart>Thompson, Ralph R%' "
      # q << " or desc_metadata like '%namePart>Skinner, David M%' "
      # q << " or desc_metadata like '%namePart>University of Virginia. News Office%') "
      # Metadata.where(q).update_all(use_right_id: 1)

      # puts "Setting rights UND for Holsinger.."
      # q = "parent_metadata_id = 3009 and desc_metadata like \"%namePart>Holsinger's Studio (Charlottesville, Va.)%\""
      # Metadata.where(q).update_all(use_right_id: 11)

      # Update to match these requirements:
      # https://confluence.lib.virginia.edu/pages/viewpage.action?spaceKey=MDS&title=DPLA+Harvest+and+Rights+Information
      # these are in DPLA
      q = "parent_metadata_id = 3009 and dpla=0 and ( "
      q << " desc_metadata like '%namePart>Thompson, Ralph R.%' "
      q << " or desc_metadata like '%namePart>Skinner, David M., 1921-2009%' "
      q << " or desc_metadata like '%namePart>Anderson, Richard N.%' "
      q << " or desc_metadata like '%namePart>University of Virginia. News Office%' "
      q << " or desc_metadata like \"%namePart>Holsinger's Studio (Charlottesville, Va.)%\""
      Metadata.where(q).update_all(dpla: 1)

      # all others are NOT DPLA (just a NOT on the or conditions)
      q = "parent_metadata_id = 3009 and dpla=1 and NOT ( "
      q << " desc_metadata like '%namePart>Thompson, Ralph R.%' "
      q << " or desc_metadata like '%namePart>Skinner, David M., 1921-2009%' "
      q << " or desc_metadata like '%namePart>Anderson, Richard N.%' "
      q << " or desc_metadata like '%namePart>University of Virginia. News Office%' "
      q << " or desc_metadata like \"%namePart>Holsinger's Studio (Charlottesville, Va.)%\""
      Metadata.where(q).update_all(dpla: 0)
   end

   desc "Add visual history by creator and optional use right"
   task :add_visual_history => :environment do
      creator = ENV['creator']
      right_str = ENV['rights']
      abort("creator and rights are required") if creator.blank? || right_str.nil?

      use_right = UseRight.where("uri like '%#{right_str}%'").first
      puts "Add '#{creator}' from visual history with rights: #{use_right.name}"

      q = "parent_metadata_id = 3009 and desc_metadata like '%namePart>#{creator}%'"
      cnt = Metadata.where(q).count
      abort("No matching records found") if cnt == 0

      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "   #{cnt} records will be added..."
      cnt = 0
      Metadata.where(q).each do |m|
         if m.dpla == false && m.in_dl?
            m.update(dpla: true, use_right_id: use_right.id)
         else
            m.update(use_right_id: use_right.id)
         end
         if m.in_dl? && m.dpla == true
            begin
               puts "Generate #{m}.id : #{m.title}"
               PublishQDC.generate_qdc(m, qdc_dir, qdc_tpl)
               m.update(qdc_generated_at: DateTime.now)
               cnt += 1
            rescue Exception=>e
               puts "ERROR: Unable to generate QDC for this record; skipping it. Cause: #{e}"
               puts e.backtrace
               puts "==============================================================================="
            end
         end
      end
      puts "DONE. Generated #{cnt} QDC records"
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
         relative_pid_path = QDC.relative_pid_path(m.pid)
         del_path = File.join(qdc_dir, relative_pid_path, "#{m.pid}.xml")
         if File.exist?(del_path)
            puts "   remove #{del_path}"
            m.update(dpla: false, qdc_generated_at: nil)
            # File.delete(del_path)
            cmd = "cd #{qdc_dir}; git rm #{File.join(relative_pid_path, "#{m.pid}.xml")}"
            `#{cmd}`
            cnt +=1
         end
      end
      puts "Removed #{cnt} untitled records"
   end

   desc "Generate DPLA QDC a single record"
   task :generate_single  => :environment do
      pid = ENV['pid']
      abort("PID is required") if pid.nil?

      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      begin
         meta = Metadata.find_by(pid: pid)
         PublishQDC.generate_qdc(meta, qdc_dir, qdc_tpl)
         meta.update(qdc_generated_at: DateTime.now)
      rescue Exception=>e
         puts "ERROR: Unable to generate QDC for this record; skipping it. Cause: #{e}"
         puts e.backtrace
         puts "==============================================================================="
      end
   end

   desc "Generate DPLA QDC for all children of a single collection record"
   task :generate_collection  => :environment do
      id = ENV['id']
      abort("id is required") if id.blank?

      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      meta = Metadata.find(id)
      puts "===> Processing collection #{meta.id}: #{meta.title}"
      ts0 = Time.now
      cnt = generate_collection_qdc(meta.id, qdc_tpl, -1)
      dur = (Time.now-ts0).round(2)
      puts "===> DONE. #{cnt} records generated. Elapsed seconds: #{dur}"
   end

   desc "Generate QDC for all UVA printing service collections"
   task :generate_printing_service => :environment do
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      q =  "select * from metadata where title = 'University of Virginia Printing Services photograph file and index'"
      q << " and dpla = 1 and date_dl_ingest is not null"

      total = 0
      colls = 0
      total_time = 0
      Metadata.find_by_sql(q).each do |m|
         puts "===> Processing collection #{m.id}: #{m.title}"
         colls +=1
         ts0 = Time.now
         total += generate_collection_qdc(m.id, qdc_tpl, -1)
         dur = (Time.now-ts0).round(2)
         total_time += dur
         puts "===> DONE. Elapsed seconds: #{dur}"
      end

      puts
      puts "FINISHED! Generated #{total} QDC records from #{colls} collections in #{(total_time/60).round(3)} minutes"
   end

   desc "Generate DPLA QDC for all collection records"
   task :generate_orphaned_xml  => :environment do
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      puts "Reading QDC xml template..."
      file = File.open( File.join(Rails.root,"app/views/template/qdc.xml"), "rb")
      qdc_tpl = file.read
      file.close

      q = "select id from metadata where dpla=1 and parent_metadata_id=0 and discoverability = 1"
      q << " and date_dl_ingest is not null and type='XmlMetadata'"
      total_time = 0
      total = 0
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
      puts "FINISHED! Generated #{total} QDC records from in #{(total_time/60).round(3)} minutes"
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
      q << " where mc.parent_metadata_id > 0 and mp.dpla = 1 and mp.date_dl_ingest is not null"
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
      q << " where parent_metadata_id = 0 and dpla = 1 and date_dl_ingest is not null"
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

      # More orphaned items...
      q = "select id from metadata where dpla=1 and parent_metadata_id=0 and discoverability = 1"
      q << " and date_dl_ingest is not null and type='XmlMetadata'"
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

   desc "remove all dpla collections where exemplar is a missing image placeholder"
   task :remove_placholders  => :environment do
      q = "select distinct m.pid from master_files mf"
      q << " inner join metadata m on mf.metadata_id = m.id where filesize=507620 and dpla=1"
      cnt = 0
      qdc_dir = "#{Settings.delivery_dir}/dpla/qdc"
      abort("QDC delivery dir #{qdc_dir} does not exist") if !Dir.exist? qdc_dir

      Metadata.find_by_sql(q).each do |m|
         puts "#{m.pid} has a placeholder image"
         relative_pid_path = QDC.relative_pid_path(m.pid)
         pid_path = File.join(qdc_dir, relative_pid_path)
         qdc_fn = File.join(pid_path, "#{m.pid}.xml")
         if File.exist? qdc_fn
            puts "  removing existing file that was published to DPLA."
            cnt +=1
            cmd = "cd #{qdc_dir}; git rm #{File.join(relative_pid_path, "#{m.pid}.xml")}"
            puts "   #{cmd}"
            `#{cmd}`
         else
            puts "   this item has not been published to DPLA. Nothing to do."
         end
      end
      puts "Removed #{cnt} items from DPLA"
   end
end

