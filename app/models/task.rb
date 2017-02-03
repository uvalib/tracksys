class Task < ActiveRecord::Base
   enum priority: [:normal, :high, :critical]
   enum item_type: [:bound, :flat, :slide, :negative, :oversize]
   enum item_condition: [:good, :bad]

   belongs_to :workflow
   belongs_to :unit
   belongs_to :owner, :class_name=>"StaffMember"
   belongs_to :current_step, :class_name=>"Step"

   has_one :order, :through => :unit
   has_one :customer, :through => :order

   has_many :assignments

   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :due_on,  :presence => true

   scope :unassigned, ->{where(owner: nil) }
   scope :overdue, ->{where("due_on < ?", Date.today.to_s) }

   before_create do
      self.added_at = Time.now
      self.current_step = self.workflow.first_step
   end

   def started?
      return !self.started_at.nil?
   end

   def finished?
      return !self.finished_at.nil?
   end

   def finish_assignment
      self.active_assignment.update(finished_at: Time.now)
      if self.current_step.final?
         Rails.logger.info("Workflow [#{self.workflow.name}] is now complete")
         return self.update(finished_at: Time.now, owner: nil, current_step: nil)
      end

      # Advance to next step, and preserve owner if flagged
      new_step = self.current_step.next_step
      if self.current_step.propagate_owner
         Rails.logger.info("Workflow [#{self.workflow.name}] advanced to next step [#{new_step.name}], owner perserved")
         self.update(current_step: new_step)
         Assignment.create(task: self, staff_member: self.owner, step: new_step)
      else
         Rails.logger.info("Workflow [#{self.workflow.name}] advanced to next step [#{new_step.name}]")
         self.update(current_step: new_step, owner: nil)
      end
   end

   def project_name
      return self.unit.order.title
   end

   def percentage_complete
      num_steps = self.workflow.num_steps*3 # each step has 3 parts, assigned, in-process and done
      curr_step = 0
      self.assignments.each do |a|
         if !a.step.failure?
            curr_step +=1
            curr_step +=1 if !a.started_at.nil?
            curr_step +=1 if !a.finished_at.nil?
         end
      end
      return (curr_step.to_f/num_steps.to_f*100).to_i
   end

   def active_assignment
      return nil if self.assignments.count == 0
      return self.assignments.last
   end

   def status_text
      if assignments.count == 0
         s = self.workflow.first_step
         return "No progress"
      else
         s = self.current_step
         msg = "Not started"
         msg = "In progress" if assignments.last == s && !assignments.last.started_at.nil?
         return "#{s.name}: #{msg}"
      end
   end

   def next_step
      return self.workflow.first_step if self.assignments.count == 0
      # TODO
   end
end
