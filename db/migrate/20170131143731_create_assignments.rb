class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.references :task, index: true
      t.references :step, index: true
      t.references :staff_member, index: true
      t.datetime  :assigned_at
      t.datetime  :started_at
      t.datetime  :finished_at
    end
  end
end
