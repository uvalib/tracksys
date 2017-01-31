class Task < ActiveRecord::Base
   enum condition: [:good, :bad]
   enum priority: [:normal, :high, :critical]
   enum category: [:book, :manuscript, :slide, :cruse_scan]

   belongs_to :workflow
   belongs_to :unit
   belongs_to :owner, :class_name=>"StaffMember"
   has_one :order, :through => :unit
   has_one :customer, :through => :order

   has_many :assignments

   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :due_on,  :presence => true

   scope :unassigned, ->{where(owner: nil) }

   before_create do
      self.added_at = Time.now
   end

   def started?
      return !self.started_at.nil?
   end

   def finished?
      return !self.finished_at.nil?
   end

   def project_name
      return self.unit.order.title
   end

   def percentage_complete
      num_steps = self.workflow.num_steps*3 # each step has 3 parts, assigned, in-process and done
      curr_step = 0
      self.assignments.each do |a|
         if !a.step.fail?
            curr_step +=1
            curr_step +=1 if !a.started_at.nil?
            curr_step +=1 if !a.finished_at.nil?
         end
      end
      return (curr_step.to_f/num_steps.to_f*100).to_i
   end

   def curr_step_info
      if assignments.count == 0
         s = self.workflow.first_step
         return "No progress"
      else
         s = self.assignments.last.step
         msg = "Not started"
         msg = "In progress" if !assignments.last.started_at.nil?
         return "#{s.name}: #{msg}"
      end
   end

   def next_step
      return self.workflow.first_step if self.assignments.count == 0
      # TODO
   end
end
