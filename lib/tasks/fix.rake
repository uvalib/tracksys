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
end
