class AddEmailToStaffMembers < ActiveRecord::Migration
  def change
    add_column :staff_members, :email, :string
  end
end
