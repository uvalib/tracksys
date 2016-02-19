class JobStatus < ActiveRecord::Base
   belongs_to :originator, :polymorphic=>true
   validates :status, inclusion: {
      in: ["pending", "running", "success", "failure"],
      message: "%{value} is not a valid size" }


   def started
      self.update_attributes(:started_at => DateTime.now, :status=>"running") if self.status == 'pending'
   end

   def failed(err)
      # only handle this if the status is transitiong from running to failed
      return if self.status != 'running'
      self.update_attributes(:ended_at => DateTime.now, :status=>"failure", :active_error=>true, :error=>err)
   end

   def finished
      self.update_attributes(:ended_at => DateTime.now, :status=>"success") if self.status == 'running'
   end

   def self.jobs_count(status)
      return JobStatus.where(status: status).count
   end
end
