#encoding: utf-8
namespace :fix do
   desc "Editor role retire"
   task :retire_editor  => :environment do
      StaffMember.all.each do |s|
         role_id = StaffMember.roles[s.role]
         if role_id > 1
            role_id -= 1
            s.update(role: role_id)
            puts "Updated role for #{s.email}"
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
         deliverable_format: "tiff", deliverable_resolution: "Highest Possible", deliverable_resolution_unit: "dpi")
      IntendedUse.find(107).update(is_approved: 0)    # academic print pub
      IntendedUse.find(108).update(is_approved: 0)    # non-academic print public
      IntendedUse.find(111).update(is_approved: 0)    # sharing
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
end
