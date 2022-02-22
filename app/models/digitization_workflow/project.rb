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
   scope :failed_qa, ->{ joins("inner join steps s on current_step_id = s.id" ).where("step_type = 2") }
   scope :overdue, ->{where("due_on < ? and finished_at is null", Date.today.to_s).reorder(due_on: :asc) }

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

   def active_assignment
      return nil if self.assignments.count == 0
      return self.assignments.order(assigned_at: :asc).last
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
