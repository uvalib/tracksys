class AddAutomationMessageCounterToStaffMembers < ActiveRecord::Migration
  def change
    change_table(:staff_members) do |t|
      t.integer :automation_messages_count, :default => 0
    end
  end
end
