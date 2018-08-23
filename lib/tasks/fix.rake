#encoding: utf-8
namespace :fix do
   # One time fix for missing folders in manuscripts
   task :missing_folders => :environment do
      uid = ENV['id']
      abort("id param is required") if uid.nil?
      unit = Unit.find(uid)
      js = JobStatus.where("originator_id=? and originator_type=? and status=?", uid, "Unit", "success")
      abort("Multiple job status reports. Must be done manually") if js.length > 1
      job_id = js.first.id
      job_file = File.join(Rails.root, "log", "jobs", "job_#{job_id}.log")

      curr_mf = nil
      found_create_lines = false
      puts "Unit #{uid} finalizaed with job #{job_file}"
      File.open(job_file, "r").each_line do |line|
         # Identify the pairs of lines in the log file that to a master file to a location
         # Pair is: 'Create new master' and 'Creating location metadata' Once one is found,
         # flag it. After the pair is a line about manuscripts. Skip it. Once anththing
         # else is found after flagging the start of date, we are done.
         if line.include? "Create new master"
            found_create_lines = true
            tf = line.split(" ").last
            puts "Processing master file #{tf}..."
            curr_mf = unit.master_files.find_by(filename: tf)
            abort("No master file #{tf} found") if curr_mf.nil?
         elsif line.include? "Creating location metadata"
            subdir_str = line.split(" ").last.gsub /(\[|\])/, ""
            abort("Found box/folder info, but dont have masterfile") if curr_mf.nil?
            puts "   location info #{subdir_str}"
            folder = subdir_str.split("/").last
            box_id = subdir_str.split("/").first.split(".").last
            abort "master file does not have any location info." if curr_mf.location.nil?
            loc = curr_mf.location
            abort("Current box_id mismatch: #{loc.container_id} vs #{box_id}") if loc.container_id != box_id
            abort("Masterfile already has a location with different folder info") if !loc.folder_id.nil? && loc.folder_id != folder
            puts "   set folder to #{folder}"
            loc.update!(folder_id: folder)
         elsif found_create_lines == true && !line.include?("Link manuscript")
            puts "Found non-create line. Done."
            break
         end
      end
   end

   # NOTE: This is a one time task that should be run after the DB
   # is migrated to support the new order pre-pay workflow
   desc "Add invoices for orders in await_fee state"
   task :await_fee_invoice =>:environment do
      Order.where("order_status=? and invoices_count=?", "await_fee", 0).each do |o|
         puts "Create invoice for:"
         puts "  #{o.id} fee #{o.fee} date sent #{o.date_fee_estimate_sent_to_customer}"
         d = o.date_fee_estimate_sent_to_customer
         d = Time.now if d.blank?
         invoice = Invoice.create!(order_id: o.id, date_invoice: d)
      end
   end

   task :death_date_report =>:environment do
      q = 'master_files.creator_death_date is not null and master_files.creator_death_date <> ""'
      Metadata.joins(:master_files).where(q).distinct.each do |m|
       dd= ""
       bad = []
        m.master_files.each do |mf|
           next if mf.creator_death_date.blank?
           next if mf.creator_death_date == "unknown"
           if dd.blank?
             puts "===> Metadata #{m.id} death date #{mf.creator_death_date}"
             dd = mf.creator_death_date
             next
           end
           if mf.creator_death_date.include?(",") ||  mf.creator_death_date.include?("and")
              puts "   Metadata #{m.id}, MF #{mf.id} death_date badly formed #{mf.creator_death_date}"
           elsif mf.creator_death_date != dd
             puts "   Metadata #{m.id}, MF #{mf.id} death_date mismatch #{mf.creator_death_date}"
           end
        end
     end
   end
   desc "Fix missing dimensions in image metadata"
   task :blank_size  => :environment do
      puts "Fixing blank dimensions..."
      cnt = 0
      ImageTechMeta.where('width is null').each do |md|
         print(".")
         unit_dir = "%09d" % md.master_file.unit_id
         mf_path = File.join(ARCHIVE_DIR, unit_dir, md.master_file.filename)
         if File.exist? mf_path
            cmd = "identify #{mf_path}"
            cnt += 1
            out = `#{cmd}`
            size = out.split(" ")[2]
            wh = size.split("x")
            md.update!(width: wh[0], height: wh[1])
         else
            puts "ERROR: #{mf_path} not found"
         end
      end
      puts "\nDONE"
      puts "Fixed #{cnt} master files"
   end

   desc "Update creator name for XmlMetadata"
   task :creator_name  => :environment do
      puts "Updating creator_name for XmlMetadata..."
      XmlMetadata.all.find_each do |metadata|
          print(".")
          xml = Nokogiri::XML( metadata.desc_metadata )
          xml.remove_namespaces!
          creator = []
          first_node = xml.xpath("/mods/name").first
          if !first_node.nil?
             first_node.xpath("namePart").each do |node|
                creator << node.text.strip
             end
          end
          if !creator.blank?
             creator_name = creator.join(" ")
             if creator_name != metadata.creator_name
                metadata.update(creator_name: creator_name)
             end
          end
      end
   end

   desc "completed orders"
   task :completed_orders  => :environment do
      puts "Detect completed orders and flag them as complete"
      Order.where(order_status: 'approved').find_each do |o|
         # already marked complete. nothing to do
         next if !o.date_completed.nil?

         # If date_customer_notified is set, this is safe to consider complete
         if !o.date_customer_notified.nil?
            puts "Marking PATRON order #{o.id} complete"
            o.update(order_status: "completed", date_completed: o.date_customer_notified)
         elsif !o.date_archiving_complete.nil?
            puts "Marking archived order #{o.id} complete"
            o.update(order_status: "completed", date_completed: o.date_archiving_complete)
         else
            puts "questionable order staaus #{o.id}"
         end
      end
   end

   desc "fix blank genre/resource type. Replace blank with NULL"
   task :blank_metadata_info => :environment do
      q = "update metadata set resource_type=null where resource_type = ''"
      Metadata.connection.execute(q)
      q = "update metadata set genre=null where genre = ''"
      Metadata.connection.execute(q)
      q = "update metadata set creator_name=null where creator_name = ''"
      Metadata.connection.execute(q)
   end

   desc "Deactivate combine and create new intended uses"
   task :intended_use => :environment do
      IntendedUse.create(description: "Print Publication", is_internal_use_only: 0, is_approved: 1,
         deliverable_format: "tiff", deliverable_resolution: "Highest Possible")
      IntendedUse.find(107).update(is_approved: 0)    # academic print pub
      IntendedUse.find(108).update(is_approved: 0)    # non-academic print public
      IntendedUse.find(111).update(is_approved: 0)    # sharing
   end

   desc "Add parent setting for XML metadata that needs it"
   task :xml_parent => :environment do
      XmlMetadata.where(parent_metadata_id: 0).each do |m|
         print "."
         if m.master_files.count == 0
            #puts "XmlMetadata #{m.id} has no master files. Skipping"
            next
         end
         unit = m.master_files.first.unit
         if unit.nil?
            #puts "Unable to find unit for XmlMetadata #{m.id}"
            next
         end
         if unit.metadata.id == m.id
            #puts "XmlMetadata #{m.id} same as unit metadata. Don't set parent"
            next
         end
         puts "XmlMetadata #{m.id}: set parent to #{unit.metadata.id}"
         m.update(parent_metadata_id: unit.metadata_id)
      end
   end

   desc "Migrate DPLA flag from unit metadata to XmlMetadata"
   task :xml_dpla => :environment do
      # Get all metadata flagged for inclusion in DPLA...
      Metadata.where(dpla:true).each do |dpla_md|
         # Only care about units of this metadata that are in the DL...
         dpla_md.units.where(include_in_dl: true).where(reorder: false).each do |u|
            # Get all of the master files associated with the unit that have XmlMetadata
            puts "Check masterfile metadata for unit #{u.id}, metadata #{dpla_md.id}"
            u.master_files.joins(:metadata).where("metadata.type='XmlMetadata'").each do |xm|
               # if the master file metadata is different than the unit metadata, make sure
               # the data is set correctly
               if u.metadata.id != xm.metadata.id
                  puts "   ==> Update XmlMetadata #{xm.id} - prior parent/dpla: #{xm.metadata.parent_metadata_id}/#{xm.metadata.dpla}"
                  xm.metadata.update(parent_metadata_id: dpla_md.id, dpla: true)
               end
            end
         end
      end
   end

   desc "Export staff skills matrix to json"
   task :export_skills => :environment do
      out = []
      StaffMember.all.each do |u|
         skills = []
         u.skills.each do |s|
            skills << {id: s.id, name: s.name}
         end
         staff = {computing_id: u.computing_id, last_name: u.last_name, first_name: u.first_name,
            role: u.role, email: u.email}
         out<< { staff: staff, skills: skills }
      end
      puts out.to_json
   end

   desc "IMPORT staff skills matrix from json"
   task :import_skills => :environment do
      f = ENV['file']
      abort "File is required" if f.nil?
      json = File.read(f)
      data = JSON.parse(json)
      data.each do |d|
         computing_id = d['staff']['computing_id']
         puts "Import skills for staff member #{computing_id}"
         staff = StaffMember.find_by(computing_id: computing_id)
         if staff.nil?
            puts "Staff Member #{computing_id} does not exist. Create (y/n)?"
            input = STDIN.gets.strip
            if input == 'y'
               puts "Creating staff member #{computing_id}"
               a = d['staff']
               staff = StaffMember.create!(
                  computing_id: a['computing_id'], last_name: a['last_name'],
                  first_name: a['first_name'], is_active: true, email: a['email'],
                  role: StaffMember.roles[ a['role'] ] )
            else
               puts "Skipping staff member #{computing_id}"
               next
            end
         end

         # add skills to staff member
         puts "Adding skills"
         d['skills'].each do |skill|
            c = Category.find(skill['id'])
            if !staff.skills.include? c
               staff.skills << c
               puts "   added #{c.name}"
            end
         end
      end
   end

   desc "fix missing PID/IIIF"
   task :missing_pid => :environment do
      uid = ENV['id']
      abort("id is required") if uid.nil?
      unit = Unit.find(uid)
      unit.master_files.each do |mf|
         next if !mf.pid.blank?

         pid = "tsm:#{mf.id}"
         mf.update(pid: pid)
         src = File.join(Settings.archive_mount, unit.id.to_s.rjust(9, "0") )
         puts "MF #{mf.id} new PID #{mf.pid}, src: #{src}"
         publish_to_iiif(mf, "#{src}/#{mf.filename}" )
      end
   end

   desc "checkout"
   task :checkout => :environment do
      q = "date_materials_received is not null and metadata.type='SirsiMetadata'"
      Unit.joins(:metadata).where(q).order("date_materials_received asc").find_each do |u|
         print "."
         if u.date_materials_returned.nil?
            if u.date_materials_received.strftime("%F") < "2016"
               # prior to 2016, assume item was checked in 3 months later
               Checkout.create(metadata_id: u.metadata_id, checkout_at: u.date_materials_received, returned_at: u.date_materials_received+3.months)
            else
               # from 2016 on, leave item checked out
               Checkout.create(metadata_id: u.metadata_id, checkout_at: u.date_materials_received)
            end
         else
            Checkout.create(metadata_id: u.metadata_id, checkout_at: u.date_materials_received, returned_at: u.date_materials_returned)
         end
      end
   end

   desc "fix duplicate barcodes"
   task :duplicate_barcodes => :environment do
      q = "select id,barcode from metadata m "
      q << " where type = 'SirsiMetadata' and barcode <> '' "
      q << " GROUP BY barcode "
      q << " HAVING ( COUNT(barcode) = 2 ) order by cnt asc"
      Statistic.connection.execute(q).each do |resp|
         bc = resp[1]
         dup_id = resp[0]
         SirsiMetadata.where("barcode=?", bc).each do |sm|
            if sm.units.count == 0
               if sm.master_files.count == 0
                  puts "#{sm.id}: #{bc} is an UNUSED DUPLICATE"
                  sm.destroy
               else
                  puts "#{sm.id} : #{bc} HAS NO UNITS but used #{resp[5]} times"
                  mf = sm.master_files.first
                  md  = mf.unit.metadata
                  puts "...but MF belong to a unit with metadata #{md.id}, #{md.barcode}"
                  puts "... SKIPPING ODD CASE"
                  break
               end
            else
               if sm.units.count > max_unit
                  max_unit = sm.units.count
                  tgt_md_id = sm.id
               end
            end
            if tgt_md_id > -1
               puts "BARCODE #{bc} should consolidate to MD #{tgt_md_id} with #{max_unit} units"
            end
         end
      end
   end

   desc "fix UNUSED duplicate barcodes"
   task :unused_duplicate_barcodes => :environment do
      q = "select id,barcode from metadata m "
      q << " where type = 'SirsiMetadata' and barcode <> '' "
      q << " GROUP BY barcode "
      q << " HAVING ( COUNT(barcode) >1 )"
      Statistic.connection.execute(q).each do |resp|
         bc = resp[1]
         SirsiMetadata.where("barcode=?", bc).each do |sm|
            if sm.units.count == 0 &&  sm.master_files.count == 0
               puts "#{sm.id}: #{bc} is an UNUSED DUPLICATE"
               sm.destroy
            end
         end
      end
   end
end
