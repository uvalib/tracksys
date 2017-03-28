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

   desc "fix final qa"
   task :final_qa => :environment do
      Step.all.each do |s|
        s.update(start_dir: "scan/80_final_QA") if s.start_dir == "scan/80_final_qa"
        s.update(finish_dir: "scan/80_final_QA") if s.finish_dir == "scan/80_final_qa"
      end
   end
end
