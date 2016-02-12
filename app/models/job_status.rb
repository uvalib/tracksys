class JobStatus < ActiveRecord::Base
   belongs_to :originator, :polymorphic=>true
   validates :status, inclusion: {
      in: ["pending", "running", "success", "failure"],
      message: "%{value} is not a valid size" }

end
