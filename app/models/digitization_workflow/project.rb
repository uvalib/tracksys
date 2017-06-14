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
   has_one :order, :through => :unit

   has_and_belongs_to_many :equipment, :join_table=>:project_equipment,  :dependent=>:destroy

   has_many :assignments,  :dependent=>:destroy
   has_many :notes,  :dependent=>:destroy

   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :due_on,  :presence => true
   validates :item_condition,  :presence => true
   validates :category,  :presence => true

   scope :active, ->{where(finished_at: nil).reorder(due_on: :asc) }
   scope :finished, ->{where("finished_at is not null").reorder(finished_at: :desc) }
   scope :failed_qa, ->{ joins("inner join steps s on current_step_id = s.id" ).where("step_type = 2") }
   scope :bound, ->{active.where(category_id: 1).reorder(due_on: :asc) }
   scope :flat, ->{active.where(category_id: 2).reorder(due_on: :asc) }
   scope :film, ->{active.where(category_id: 3).reorder(due_on: :asc) }
   scope :oversize, ->{active.where(category_id: 4).reorder(due_on: :asc) }
   scope :special, ->{active.where(category_id: 5).reorder(due_on: :asc) }
   scope :unassigned, ->{active.where(owner: nil).reorder(due_on: :asc) }
   scope :overdue, ->{where("due_on < ? and finished_at is null", Date.today.to_s).reorder(due_on: :asc) }
   scope :patron, ->{active.joins("inner join units u on u.id=unit_id").where("u.intended_use_id <> 110")}
   scope :digital_collection_building, ->{active.joins("inner join units u on u.id=unit_id").where("u.intended_use_id = 110")}
   scope :grant, ->{active
      .joins("inner join units u on u.id=unit_id inner join orders o on o.id=u.order_id inner join agencies a on a.id=o.agency_id")
      .where('a.name like "% grant" ')}

   def self.has_error
      q = "inner join"
      q << " (select * from assignments where status = 4 order by assigned_at desc limit 1) "
      q << " a on a.project_id = projects.id"
      Project.joins(q).where("projects.finished_at is null")
   end

   def self.ready_to_finalize
      q = "inner join steps on steps.id=current_step_id"
      Project.joins(q).where("steps.name = 'Finalize'")
   end

   before_create do
      self.added_at = Time.now
      self.current_step = self.workflow.first_step
   end

   def bound?
      return !self.category.blank? && self.category.name == "Bound"
   end
   def flat?
      return !self.category.blank? && self.category.name == "Flat"
   end
   def film?
      return !self.category.blank? && self.category.name == "Film"
   end
   def oversize?
      return !self.category.blank? && self.category.name == "Oversize"
   end
   def special?
      return !self.category.blank? && self.category.name == "Special"
   end

   def grant_funded?
      return false if self.unit.agency.blank?
      return self.unit.agency.name.downcase.include? " grant"
   end

   def started?
      return !self.started_at.nil?
   end

   def finished?
      return !self.finished_at.nil?
   end

   def overdue?
      return !finished? && self.due_on <= Date.today
   end

   def claimable_by? (user)
      return true if (user.admin? || user.supervisor?)   # admin/supervisor can take anyting
      return true if self.current_step.any_owner?        # anyone can take an any assignment
      return false if self.current_step.supervisor_owner? && (user.admin? || user.supervisor?)

      if self.current_step.unique_owner?
         self.assignments.each do |a|
            return false if a.staff_member.id == user.id
         end
         return true
      end

      if self.current_step.prior_owner?
         prior = self.assignments.joins(:step).where('steps.step_type <> ?', "error").order(assigned_at: :desc).first
         return prior.id == user.id
      end

      if self.current_step.original_owner?
         orig = self.assignments.all.order(assigned_at: :asc).first
         return orig.id == user.id
      end

      return false
   end

   def total_work_time
      mins = self.assignments.sum(:duration_minutes)
      h = mins/60
      mins -= (h*60)
      return "#{'%02d' % h}:#{'%02d' % mins}"
   end

   def total_wall_time
      ordered = assignments.order(assigned_at: :asc)
      return "00:00" if ordered.count == 0

      t0 = ordered.first.assigned_at
      t1 = DateTime.now
      t1 = finished_at if finished?

      del_mins = (t1.to_i-t0.to_i)/60
      h = del_mins/60
      del_mins -= (h*60)
      return "#{'%02d' % h}:#{'%02d' % del_mins}"
   end

   def clear_assignment(admin_user)
      msg = "<p>Admin user #{admin_user.full_name} canceled assignment to #{self.owner.full_name}</p>"
      Note.create(staff_member: admin_user, project: self, note_type: :comment, note: msg, step: self.current_step )
      self.active_assignment.update(status: :error )
      active_assignment.destroy
      update!(owner: nil)
   end

   def assign_to(user)
      # If someone else has this assignment, flag it as reassigned. Do not
      # mark the finished time as it was never actually finished
      if !self.owner.nil?
         active_assignment.update!(status: :reassigned)
      end
      assignment = Assignment.create!(project: self, staff_member: user, step: self.current_step)
      update!(owner: user)
   end

   # Start work on active assignment, also starting project if it wasn't already
   #
   def start_assignment
      return if self.active_assignment.nil?
      return if !self.active_assignment.started_at.nil?

      # only update project start time if it hasn't already been started
      self.update(started_at: Time.now) if !started?

      self.active_assignment.update(started_at: Time.now, status: :started)
   end

   # Reject current project, sending it into rescan
   #
   def reject(duration)
      self.active_assignment.update(finished_at: Time.now, status: :rejected, duration_minutes: duration )

      # find owner of first step and return the project to them
      step_1_owner = self.assignments.order(assigned_at: :asc).first.staff_member
      Assignment.create(project: self, staff_member: step_1_owner, step: self.current_step.fail_step)
      self.update(current_step: self.current_step.fail_step, owner: step_1_owner)
   end

   # Finalization of the associated unit was successful
   #
   def finalization_success(job)
      Rails.logger.info("Project [#{self.project_name}] completed finalization")
      self.update(finished_at: Time.now, owner: nil, current_step: nil)
      prior_duration = self.active_assignment.duration_minutes
      processing_mins = ((Time.now - job.started_at)/60.0).round
      self.active_assignment.update(finished_at: Time.now, status: :finished,
         duration_minutes: (prior_duration+processing_mins))
   end

   # Finalzation of the associated unit failed
   #
   def finalization_failure(job)
      Rails.logger.error("Project [#{self.project_name}] FAILED finalization")

      # Fail the step and increase time spent
      prior_duration = self.active_assignment.duration_minutes
      processing_mins = ((job.ended_at - job.started_at)/60.0).round
      self.active_assignment.update(duration_minutes: (prior_duration+processing_mins), status: :error )

      # Add a problem note with a summary of the issue
      prob = Problem.find(6) # Finalization
      msg = "<p>#{job.error}</p>"
      msg << "<p>Please manually correct the finalization problems. Once complete, press the Finish button for a final validation.</p>"
      msg << "<p>Error details <a href='/admin/job_statuses/#{job.id}'>here</a></p>"
      Note.create(staff_member: self.owner, project: self, note_type: :problem, note: msg, problem: prob, step: self.current_step )
   end

   # Finish assignment, automate file moves and advance project to next step
   #
   def finish_assignment(duration)
      # Grab any pre-existing durations, add them up and update
      # the current duration. This to preserve total duration if a step ends in an error
      # and is subsequently corrrected
      prior_duration = self.active_assignment.duration_minutes
      prior_duration = 0 if prior_duration.nil?
      total_duration = prior_duration + duration.to_i
      self.active_assignment.update(duration_minutes: total_duration )

      # Clone workflow is a special case; nothing needs to be done when finishing a step
      if self.workflow.name != "Clone"
         # if this is detected to be a project that was manually finalized
         # due to a finalization error, validate the finalization and exit early
         if manually_finalized?
            validate_manual_finalization
            return
         end

         # Carry out end of step validation/automation. If this fails, there
         # is nothing more to do so exit
         if !self.current_step.finish( self )
            return
         end
      end

      # Special handling for last step; begin finalization and bail early
      if self.current_step.end?
         if self.workflow.name == "Clone"
            validate_clone_deliverables
            return
         else
            self.active_assignment.update(status: :finalizing)
            Rails.logger.info("Workflow [#{self.workflow.name}] is now complete. Starting Finalization.")
            FinalizeUnit.exec({project_id: self.id, unit_id: self.unit_id})
            return
         end
      end

      # Advance to next step, enforcing owner type
      self.active_assignment.update(finished_at: Time.now, status: :finished)
      new_step = self.current_step.next_step
      if new_step.prior_owner?
         # Create a new assignment with staff_member set to current owner.
         Rails.logger.info("Workflow [#{self.workflow.name}] advanced to [#{new_step.name}], owner preserved")
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
         # any, unique or supervisor for this step. Someone must claim it, so set owner nil.
         # user type will be enforced in the CLAIM for these
         Rails.logger.info("Workflow [#{self.workflow.name}] advanced to [#{new_step.name}]. No owner set.")
         self.update(current_step: new_step, owner: nil)
      end
   end

   def fail_clone_validation(reason)
      prob = Problem.find(7) # Other
      msg = "<p>Validation of patron deliverables failed: #{reason}</p>"
      Note.create(staff_member: self.owner, project: self, note_type: :problem, note: msg, problem: prob, step: self.current_step )
      self.active_assignment.update(status: :error )
   end

   def validate_clone_deliverables
      # check date delverables ready
      if self.unit.order.date_patron_deliverables_complete.nil?
         fail_clone_validation("Date deliverables ready not set")
         return false
      end

      # ensure there is a properly named set of deliverables present
      #    digiserv-delivery/patron/order_####/[order#.pdf] and unit_*.zip
      order_dir = File.join(DELIVERY_DIR, "order_#{order.id}")
      if !Dir.exists?(order_dir)
         fail_clone_validation("Missing order delivery directory #{order_dir}")
         return false
      end
      order_pdf = File.join(order_dir, "#{order.id}.pdf")
      if !File.exists?(order_pdf)
         fail_clone_validation("Missing order PDF #{order_pdf}")
         return false
      end

      if  Dir[File.join(order_dir, "#{self.unit.id}*.zip")].count == 0
         fail_clone_validation("No zip delivery files found")
         return false
      end

      Rails.logger.info("Project [#{self.project_name}] completed validation of cloned files")
      self.update(finished_at: Time.now, owner: nil, current_step: nil)
      self.active_assignment.update(finished_at: Time.now, status: :finished)
   end

   def project_name
      return self.unit.order.title
   end

   def percentage_complete
      num_steps = self.workflow.num_steps*3 # each step has 3 parts, assigned, in-process and done
      curr_step = 0
      step_ids = []
      self.assignments.joins(:step).each do |a|
         if !a.step.error? && !step_ids.include?(a.step.id) && !a.reassigned? && !a.error?
            # Rejections generally count as a completion as they finish the step. Per team, reject moves to a rescan.
            # When rescan is done, the workflow proceeds to the step AFTER the one that was rejected.
            # The exception to this is the last step. If rejected, completing the rescan returns
            # to that step, not the next. This is the case we need to skip when computing percentage complete.
            next if a.rejected? && a.step.fail_step.next_step == a.step

            step_ids << a.step.id
            curr_step +=1  # if an assignment is here, that is the first count: Assigned
            curr_step +=1 if !a.started_at.nil?    # Started
            curr_step +=1 if !a.finished_at.nil?   # Finished
         end
      end
      percent =  (curr_step.to_f/num_steps.to_f*100).to_i
      if finished? && percent != 100
         Rails.logger.error("Project #{self.id} is finished, but percentage reported as #{percent}")
         percent = 100
      end
      return percent
   end

   def active_assignment
      return nil if self.assignments.count == 0
      return self.assignments.order(assigned_at: :asc).last
   end

   def status_text
      return "Finished at #{self.finished_at.strftime('%F %r')}" if finished?
      if assignments.count == 0
         s = self.workflow.first_step
         return "#{s.name}: Not assigned"
      else
         s = self.current_step
         a = self.active_assignment
         if s == a.step
            msg = "Not started"
            msg = "In progress" if assignments.order(assigned_at: :asc).last.started?
            return "#{s.name}: #{msg}"
         else
            return "#{s.name}: Not assigned"
         end
      end
   end

   private
   def manually_finalized?
      # Finalization failure is detected by the presence of
      # problem note with a cause of Finailzation
      self.notes.joins(:problem).where("problems.id=6").count > 0
   end

   private
   def validation_failed(reason)
      prob = Problem.find(6) # Finalization
      msg = "<p>Validation of manual finalization failed: #{reason}</p>"
      Note.create(staff_member: self.owner, project: self, note_type: :problem, note: msg, problem: prob, step: self.current_step )
      self.active_assignment.update(status: :error )
   end

   private
   def validate_manual_finalization
      Rails.logger.info("Validating manually finalized unit")
      if unit.date_archived.nil?
         validation_failed("Unit was not archived")
         return
      end

      # archive OK; make sure masterfiles all have metadata (tech and desc)
      # and that the archived file count matches masterfile count
      archive_dir = File.join(ARCHIVE_DIR, unit.directory)
      archived_tif_count = Dir[File.join(archive_dir, '*.tif')].count
      if archived_tif_count == 0
         validation_failed("No tif files found in archive")
         return
      end

      mf_count = 0
      unit.master_files.each do |mf|
         mf_count += 1
         if mf.metadata.nil?
            validation_failed("Masterfile #{mf.filename} missing desc metadata")
            return
         end
         if mf.image_tech_meta.nil?
            validation_failed("Masterfile #{mf.filename} missing tech metadata")
            return
         end
      end

      if archived_tif_count != mf_count
         validation_failed("MasterFile / tif count mismatch. #{archived_tif_count} tif files vs #{mf_count} MasterFiles")
         return
      end

      # deliverables ready (patron or dl)
      if unit.intended_use_id == 110
         if unit.date_dl_deliverables_ready.nil?
            validation_failed("DL deliverables ready date not set")
            return
         end
      else
         if unit.date_patron_deliverables_ready.nil?
            validation_failed("Patron deliverables ready date not set")
            return
         end
      end

      # Validations all passed, complete the workflow
      Rails.logger.info("Workflow [#{self.workflow.name}] is now complete")
      self.active_assignment.update(finished_at: Time.now, status: :finished)
      self.update(finished_at: Time.now, owner: nil, current_step: nil)
   end
end
