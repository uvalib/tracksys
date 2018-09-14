# == Schema Information
#
# Table name: workflows
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  description    :text(65535)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  base_directory :string(255)      default("/Users/lf6f/dev/tracksys-dev/sandbox/digiserv-production")
#  active         :boolean          default(TRUE)
#

class Workflow < ApplicationRecord
   validates :name, :uniqueness => true, :presence => true
   validates :base_directory, :presence => true
   has_many :steps

   scope :active, ->{where("active = ?", 1)}
   scope :inactive, ->{where("active = ?", 0)}

   def first_step
      return steps.find_by(step_type: "start")
   end

   def num_steps
      return steps.where("step_type <> ?", Step.step_types[:error]).count
   end
end
