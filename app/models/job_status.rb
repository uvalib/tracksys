class JobStatus < ApplicationRecord
   belongs_to :originator, :polymorphic=>true
   validates :status, inclusion: {
      in: ["pending", "running", "success", "failure"],
      message: "%{value} is not a valid size" }

   def create_logger()
      log_file_path = File.join(JOB_LOG_DIR, "job_#{self.id}.log")
      logger = Logger.new(log_file_path)
      logger.formatter = proc do |severity, datetime, progname, msg|
         "#{datetime.strftime("%Y-%m-%d %H:%M:%S")} : #{severity} : #{msg}\n"
      end
      return logger
   end

   def status_class
      return "running" if self.status == "running" ||  self.status == "pending"
      return "failed" if self.status == "failure"
      return "warn" if self.failures > 0
   end
   def started
      update(started_at: DateTime.now, status: "running") if self.status == 'pending'
   end

   def failed(err)
      # only handle this if the status is transitiong from running to failed
      return if self.status != 'running'
      update(ended_at: DateTime.now, status: "failure", error: err)
   end

   def finished
      update(ended_at: DateTime.now, status: "success") if self.status == 'running'
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
#  error           :text(65535)
#  originator_id   :integer
#  originator_type :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#
