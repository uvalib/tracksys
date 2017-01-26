class Step < ActiveRecord::Base
   enum step_type: [:start, :finish, :fail, :normal]

   validates :name, :presence => true

   belongs_to :workflow
   has_one :next_step, class_name: "Step", foreign_key: :next_step_id
   has_one :fail_step, class_name: "Step", foreign_key: :fail_step_id
end
