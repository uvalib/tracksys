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
