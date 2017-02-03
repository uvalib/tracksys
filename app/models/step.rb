class Step < ActiveRecord::Base
   enum step_type: [:start, :end, :error, :normal]

   validates :name, :presence => true

   belongs_to :workflow
   belongs_to :next_step, class_name: "Step"
   belongs_to :fail_step, class_name: "Step"
end
