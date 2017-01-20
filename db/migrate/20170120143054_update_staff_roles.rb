class UpdateStaffRoles < ActiveRecord::Migration
  def up
     add_column :staff_members, :role, :integer, default: 0
     # enum role: [:admin, :supervisor, :editor, :student, :viewer]
     StaffMember.connection.execute("update staff_members set role=0 where role_id=1")  # admin
     StaffMember.connection.execute("update staff_members set role=1 where role_id=4")  # supervisor
     StaffMember.connection.execute("update staff_members set role=2 where role_id=2")  # editor
     StaffMember.connection.execute("update staff_members set role=3 where role_id=5")  # student
     StaffMember.connection.execute("update staff_members set role=4 where role_id=3")  # viewer
  end

  def down
     remove_column :staff_members, :role
  end
end
