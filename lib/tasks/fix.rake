#encoding: utf-8
namespace :fix do
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

end
