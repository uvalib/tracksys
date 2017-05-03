class Workflow < ActiveRecord::Base
   validates :name, :uniqueness => true, :presence => true
   has_many :steps

   def first_step
      return steps.find_by(step_type: "start")
   end

   def num_steps
      return steps.where("step_type <> ?", Step.step_types[:error]).count
   end
end
