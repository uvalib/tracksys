class ConvertRoles < ActiveRecord::Migration
   def up
      remove_column :staff_members, :role
      add_column :staff_members, :role_id, :integer, references: :roles, :default=>1
   end

   def down
      remove_column :staff_members, :role_id
      add_column :staff_members, :role, :string, :null => false, :default => 'admin'
   end
end
