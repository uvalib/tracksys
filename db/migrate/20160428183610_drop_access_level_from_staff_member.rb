class DropAccessLevelFromStaffMember < ActiveRecord::Migration
   def up
      remove_column :staff_members, :access_level_id
   end

   def down
      add_column :staff_members, :access_level_id, :integer, :default=>0
   end
end
