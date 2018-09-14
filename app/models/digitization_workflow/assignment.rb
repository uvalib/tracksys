# == Schema Information
#
# Table name: assignments
#
#  id               :integer          not null, primary key
#  project_id       :integer
#  step_id          :integer
#  staff_member_id  :integer
#  assigned_at      :datetime
#  started_at       :datetime
#  finished_at      :datetime
#  status           :integer          default("pending")
#  duration_minutes :integer
#

class Assignment < ApplicationRecord
   enum status: [:pending, :started, :finished, :rejected, :error, :reassigned, :finalizing]

   belongs_to :project
   belongs_to :step
   belongs_to :staff_member
   has_one :workflow, :through=>:project

   validates :project,  :presence => true
   validates :step,  :presence => true
   validates :staff_member,  :presence => true

   before_create do
      self.assigned_at = Time.now
   end

   def in_progress?
      return started? || error? || finalizing?
   end
end
