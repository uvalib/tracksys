class Project < ActiveRecord::Base
   enum priority: [:normal, :high, :critical]
   enum item_condition: [:good, :bad]

   belongs_to :workflow
   belongs_to :unit
   belongs_to :owner, :class_name=>"StaffMember"
   belongs_to :current_step, :class_name=>"Step"
   belongs_to :category, counter_cache: true
   belongs_to :workstation

   has_one :order, :through => :unit
   has_one :customer, :through => :order

   has_and_belongs_to_many :equipment, :join_table=>:project_equipment

   has_many :assignments
   has_many :notes

   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :due_on,  :presence => true

   scope :active, ->{where(finished_at: nil).order(due_on: :asc) }
   scope :bound, ->{where(category_id: 1).order(due_on: :asc) }
   scope :flat, ->{where(category_id: 2).order(due_on: :asc) }
   scope :film, ->{where(category_id: 3).order(due_on: :asc) }
   scope :oversize, ->{where(category_id: 4).order(due_on: :asc) }
   scope :special, ->{where(category_id: 5).order(due_on: :asc) }
   scope :unassigned, ->{where(owner: nil).order(due_on: :asc) }
   scope :overdue, ->{where("due_on < ? and finished_at is null", Date.today.to_s).order(due_on: :asc) }
   default_scope { order(added_at: :desc) }

   before_create do
      self.added_at = Time.now
      self.current_step = self.workflow.first_step
   end

   def bound?
      return self.category.name == "Bound"
   end
   def flat?
      return self.category.name == "Flat"
   end
   def film?
      return self.category.name == "Film"
   end
   def oversize?
      return self.category.name == "Oversize"
   end
   def special?
      return self.category.name == "Special"
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

   def reject(duration)
      self.active_assignment.update(finished_at: Time.now, status: :rejected, duration_minutes: duration )

      #find owner of first step and return the project to them
      step_1_owner = self.assignments.order(assigned_at: :asc).first.staff_member
      Assignment.create(project: self, staff_member: step_1_owner, step: self.current_step.fail_step)
      self.update(current_step: self.current_step.fail_step, owner: step_1_owner)
   end

   def finish_assignment(duration)
      # First, move any files to thier destination if needed
      begin
         if self.current_step.move_files?
            self.current_step.move_files(self.unit)
         end
      rescue Exception => e
         # Any problems moving files around will set the assignment as ERROR and leave it
         # uncompleted. A note detailing the error will be generated. At this point, the current
         # user can try again, or manually fix the directories and finsih the step again.
         prob = Problem.find_by(name: "Other")
         note = "<p>An error occurred moving files after step completion. Not all files have been moved. "
         note << "Please check and manually move each file. When the problem has been resolved, click finish again.</p>"
         note << "<p><b>Error details:</b> #{e.to_s}</p>"
         Note.create(staff_member: self.owner, project: self, note_type: :problem, note: note, problem: prob )
         self.active_assignment.update(status: :error )
         return
      end

      # Flag current assignment as finished and not estimated time spent. Bail if this is last step
      self.active_assignment.update(finished_at: Time.now, status: :finished, duration_minutes: duration )
      if self.current_step.end?
         Rails.logger.info("Workflow [#{self.workflow.name}] is now complete")
         return self.update(finished_at: Time.now, owner: nil, current_step: nil)
      end

      # Advance to next step, enforcing owner type
      new_step = self.current_step.next_step
      if self.current_step.error?
         # Completion of an error step is a special case:
         # Ownership is returned to the QA user that rejected it originally. This assignment is
         # the last assigned, non-error step
         orig = self.assignments.joins(:step).where('steps.step_type <> ?', "error").order(assigned_at: :desc).first
         qa_user = orig.staff_member
         Rails.logger.info("Workflow [#{self.workflow.name}] returned to [#{new_step.name}] with original QA user [#{qa_user.computing_id}]")
         self.update(current_step: new_step, owner: qa_user)
         Assignment.create(project: self, staff_member: qa_user, step: new_step)
      else
         if new_step.prior_owner?
            # Create a new assignment with staff_member set to current owner. Leave project owner as is.
            Rails.logger.info("Workflow [#{self.workflow.name}] advanced to [#{new_step.name}], owner perserved")
            self.update(current_step: new_step)
            Assignment.create(project: self, staff_member: self.owner, step: new_step)
         elsif new_step.original_owner?
            # Send back to the first person assigned this project
            # Note: no need to check for nil; we are finishing an assignment, so one will always exist
            first_assign = self.assignments.all.order(assigned_at: :desc).first
            first_owner = first_assign.staff_member
            Rails.logger.info("Workflow [#{self.workflow.name}] advanced to [#{new_step.name}] with original owner [#{first_owner.computing_id}]")
            self.update(current_step: new_step, owner: first_owner)
            Assignment.create(project: self, staff_member: first_owner, step: new_step)
         else
            # any, unique or supervisor for this step. Someone must claim it, so set owner nil
            # user type will be enforced in the CLAIM for these
            Rails.logger.info("Workflow [#{self.workflow.name}] advanced to [#{new_step.name}]. No owner set.")
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
