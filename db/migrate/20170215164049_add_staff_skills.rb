class AddStaffSkills < ActiveRecord::Migration
  def change
     create_table :staff_skills do |t|
       t.references :staff_member, index: true
       t.references :category, index: true
       t.timestamps
     end
  end
end
