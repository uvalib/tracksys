class Assignment < ActiveRecord::Base
   enum status: [:pending, :started, :finished, :rejected]

   belongs_to :task
   belongs_to :step
   belongs_to :staff_member
   has_one :workflow, :through=>:task

   validates :task,  :presence => true
   validates :step,  :presence => true
   validates :staff_member,  :presence => true

   before_create do
      self.assigned_at = Time.now
   end
end
