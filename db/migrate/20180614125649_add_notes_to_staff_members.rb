class AddNotesToStaffMembers < ActiveRecord::Migration[5.2]
  def change
     add_column :staff_members, :notes, :text
  end
end
