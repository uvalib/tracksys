class JobStatus < ActiveRecord::Base
   belongs_to :originator, :polymorphic=>true
   validates :status, inclusion: {
      in: ["pending", "running", "success", "failure"],
      message: "%{value} is not a valid size" }

   def status_class
      return "running" if self.status == "running" ||  self.status == "pending"
      return "failed" if self.status == "failure"
      return "warn" if self.failures > 0
   end
   def started
      self.update_attributes(:started_at => DateTime.now, :status=>"running") if self.status == 'pending'
   end

   def failed(err)
      # only handle this if the status is transitiong from running to failed
      return if self.status != 'running'
      self.update_attributes(:ended_at => DateTime.now, :status=>"failure", :error=>err)
   end

   def finished
      self.update_attributes(:ended_at => DateTime.now, :status=>"success") if self.status == 'running'
   end

   def self.jobs_count(status)
      return JobStatus.where(status: status).count
   end

   # All successful job status records older than 2 weeks are
   # expired and removed from DB
   #
   def self.expire_completed_jobs
      expired = JobStatus.where('status=? and ended_at < ?', 'success', Date.today-2.weeks)
      if expired.count > 0
         puts "EXPIRE #{expired.count} statuses"
         expired.destroy_all
      end
   end
end
# == Schema Information
#
# Table name: job_statuses
#
#  id              :integer          not null, primary key
#  name            :string(255)      not null
#  status          :string(255)      default("pending"), not null
#  started_at      :datetime
#  ended_at        :datetime
#  failures        :integer          default(0), not null
#  error           :string(255)
#  originator_id   :integer
#  originator_type :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
