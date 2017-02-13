class Task < ActiveRecord::Base
   enum priority: [:normal, :high, :critical]
   enum item_type: [:bound, :flat, :film, :oversize, :special]
   enum item_condition: [:good, :bad]

   belongs_to :workflow
   belongs_to :unit
   belongs_to :owner, :class_name=>"StaffMember"
   belongs_to :current_step, :class_name=>"Step"

   has_one :order, :through => :unit
   has_one :customer, :through => :order

   has_many :assignments
   has_many :notes

   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :due_on,  :presence => true

   scope :active, ->{where(finished_at: nil).order(due_on: :asc) }
   scope :unassigned, ->{where(owner: nil).order(due_on: :asc) }
   scope :overdue, ->{where("due_on < ? and finished_at is null", Date.today.to_s).order(due_on: :asc) }
   default_scope { order(added_at: :desc) }

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

   def overdue?
      return self.due_on <= Date.today
   end

   def reject
      self.active_assignment.update(finished_at: Time.now, status: :rejected )

      #find owner of first step and return the task to them
      step_1_owner = self.assignments.order(assigned_at: :asc).first.staff_member
      Assignment.create(task: self, staff_member: step_1_owner, step: self.current_step.fail_step)
      self.update(current_step: self.current_step.fail_step, owner: step_1_owner)
   end

   def finish_assignment
      # First, move any files to thier destination if needed
      begin
         if self.current_step.move_files?
            self.current_step.move_files(self.unit)
         end
      rescue Exception => e
         prob = Problem.find_by(name: "Other")
         note = "An error occurred moving files after step completion. Not all files have been moved. "
         note << "Please check and manually move each file. When the problem has been resolved, click finish again."
         note << "Error details: #{e.to_s}"
         Note.create(staff_member: self.owner, task: self, note_type: :problem, note: note, problem: prob )
         self.active_assignment.update(status: :error )
         return
      end

      self.active_assignment.update(finished_at: Time.now, status: :finished )
      if self.current_step.end?
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
         if self.current_step.error?
            # if this step is a failure, completion returns it to the prior, non-error
            # step. Also restore the user who rejected it
            prior_assign = self.assignments.where(step: new_step).order(assigned_at: :desc).first
            if !prior_assign.nil?
               Rails.logger.info("Workflow [#{self.workflow.name}] reassigning failed step [#{new_step.name}] back to original owner")
               self.update(current_step: new_step, owner: prior_assign.staff_member)
               Assignment.create(task: self, staff_member: prior_assign.staff_member, step: new_step)
            else
               Rails.logger.info("Workflow [#{self.workflow.name}] advanced to next step [#{new_step.name}]")
               self.update(current_step: new_step, owner: nil)
            end
         else
            Rails.logger.info("Workflow [#{self.workflow.name}] advanced to next step [#{new_step.name}]")
            self.update(current_step: new_step, owner: nil)
         end
      end
   end

   def project_name
      return self.unit.order.title
   end

   def percentage_complete
      num_steps = self.workflow.num_steps*3 # each step has 3 parts, assigned, in-process and done
      curr_step = 0
      self.assignments.each do |a|
         if !a.step.error?
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
         return "#{s.name}: Not assigned"
      else
         s = self.current_step
         msg = "Not started"
         msg = "In progress" if assignments.last == s && !assignments.last.started_at.nil?
         return "#{s.name}: #{msg}"
      end
   end

   def start_work
      return if self.active_assignment.nil?
      return if !self.active_assignment.started_at.nil?
      self.update(started_at: Time.now)
      self.active_assignment.update(started_at: Time.now, status: :started)
   end
end
