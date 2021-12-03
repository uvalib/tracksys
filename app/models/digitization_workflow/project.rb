# == Schema Information
#
# Table name: projects
#
#  id                 :integer          not null, primary key
#  workflow_id        :integer
#  unit_id            :integer
#  owner_id           :integer
#  current_step_id    :integer
#  priority           :integer          default("normal")
#  due_on             :date
#  item_condition     :integer
#  added_at           :datetime
#  started_at         :datetime
#  finished_at        :datetime
#  category_id        :integer
#  viu_number         :string(255)
#  capture_resolution :integer
#  resized_resolution :integer
#  resolution_note    :string(255)
#  workstation_id     :integer
#  condition_note     :text(65535)
#  container_type_id  :bigint(8)
#

class Project < ApplicationRecord
   enum priority: [:normal, :high, :critical]
   enum item_condition: [:good, :bad]

   belongs_to :workflow
   belongs_to :unit
   belongs_to :owner, :class_name=>"StaffMember", optional: true
   belongs_to :current_step, :class_name=>"Step", optional: true
   belongs_to :category, counter_cache: true
   belongs_to :workstation, optional: true
   belongs_to :container_type, optional: true

   has_one :order, :through => :unit
   has_one :customer, :through => :order
   has_one :metadata, :through => :unit

   has_and_belongs_to_many :equipment, :join_table=>:project_equipment,  :dependent=>:destroy

   has_many :assignments,  :dependent=>:destroy
   has_many :notes,  :dependent=>:destroy

   validates :workflow,  :presence => true
   validates :unit,  :presence => true
   validates :due_on,  :presence => true
   validates :item_condition,  :presence => true
   validates :category,  :presence => true

   scope :active, ->{where(finished_at: nil).reorder(due_on: :asc) }
   # Get a list of projects per user/date/workflow/tyoe
   #
   def self.filter(type, staff_id, workflow, start_date, end_date, rejects_only)
      q = "select a.* from assignments a"
      q << " inner join projects p on a.project_id=p.id"
      q << " inner join steps s on s.id=a.step_id"
      q << " where p.workflow_id=#{workflow.to_i}"
      q << " and p.finished_at >= #{sanitize(start_date)} and p.finished_at <= #{sanitize(end_date)}"
      q << " and a.status != 5 and (s.step_type = 0 or fail_step_id is not null)"
      # status 5 is reassignined, step types: [:start, :end, :error, :normal]
      # step 0 = is the initial scan all of the following steps are also scan
      # Steps with a fail step are QA

      projects = []
      # curr_project = nil
      scan_projects = []
      Assignment.find_by_sql(q).each do |a|
         if type == "qa"
            next if a.staff_member_id != staff_id
            next if a.step.start?
            next if !a.rejected? && rejects_only
            projects << a.project
         else
            if a.step.start?
               next if a.staff_member_id != staff_id
               # track all of the projects this user scanned
               scan_projects << a.project.id if !scan_projects.include? a.project.id
               puts "scanned projects #{scan_projects}"
            else
               if scan_projects.include? a.project.id
               # if a.project_id == curr_project
                  if rejects_only == false
                     puts "Not reject only; accept all"
                     projects << a.project
                  else
                     if a.rejected?
                        puts "rejects: #{rejects_only} status #{a.rejected?}: KEEP"
                        projects << a.project
                     end
                  end
               end
            end
         end
      end
      return projects.uniq
   end

   private
   def self.sanitize(text)
      return ActiveRecord::Base::connection.quote(text)
   end

   public
   def self.has_error
      q = "inner join"
      q << " (select * from assignments where status = 4 order by assigned_at desc limit 1) "
      q << " a on a.project_id = projects.id"
      Project.joins(q).where("projects.finished_at is null")
   end

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

   def project_name
      name = self.unit.metadata.title
      name = "" if name.nil?
      return name
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

   # Finalization of the associated unit was successful
   #
   def finalization_success(job)
      Rails.logger.info("Project [#{self.project_name}] completed finalization")
      processing_mins = ((Time.now - job.started_at)/60.0).round
      validate_finalization(processing_mins)
   end

   # Finalzation of the associated unit failed
   #
   def finalization_failure(job)
      Rails.logger.error("Project [#{self.project_name}] FAILED finalization")

      # Fail the step and increase time spent
      processing_mins = ((job.ended_at - job.started_at)/60.0).round
      qa_mins = self.active_assignment.duration_minutes
      qa_mins = 0 if qa_mins.nil?
      Rails.logger.info("Project [#{self.project_name}] finalization minutes: #{processing_mins}, prior minutes: #{qa_mins}")
      self.active_assignment.update(duration_minutes: (processing_mins+qa_mins), status: :error )

      # Add a problem note with a summary of the issue
      prob = Problem.find(6) # Finalization
      msg = "<p>#{job.error}</p>"
      msg << "<p>Please manually correct the finalization problems. Once complete, press the Finish button to restart finalization.</p>"
      msg << "<p>Error details <a href='/admin/job_statuses/#{job.id}'>here</a></p>"
      note = Note.create(staff_member: self.owner, project: self, note_type: :problem, note: msg, step: self.current_step )
      note.problems << prob
   end

   private
   def validation_failed(reason)
      prob = Problem.find(6) # Finalization
      msg = "<p>Validation of finalization failed: #{reason}</p>"
      note = Note.create(staff_member: self.owner, project: self, note_type: :problem, note: msg, step: self.current_step )
      note.problems << prob
      self.active_assignment.update(status: :error )
   end

   private
   def validate_finalization(processing_mins)
      Rails.logger.info("Validating finalized unit")
      if !unit.throw_away
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

      if !unit.throw_away
         if archived_tif_count != mf_count
            validation_failed("MasterFile / tif count mismatch. #{archived_tif_count} tif files vs #{mf_count} MasterFiles")
            return
         end
      end

      # deliverables ready (patron or dl)
      if unit.intended_use_id == 110
         if unit.date_dl_deliverables_ready.nil? && unit.include_in_dl
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
      # self.active_assignment.update(finished_at: Time.now, status: :finished)
      self.update(finished_at: Time.now, owner: nil, current_step: nil)
      qa_mins = self.active_assignment.duration_minutes
      qa_mins = 0 if qa_mins.nil?
      Rails.logger.info("Project [#{self.project_name}] finalization minutes: #{processing_mins}, prior minutes: #{qa_mins}")
      self.active_assignment.update(finished_at: Time.now, status: :finished, duration_minutes: (processing_mins+qa_mins) )
   end
end
