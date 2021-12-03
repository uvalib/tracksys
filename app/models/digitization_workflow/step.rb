# == Schema Information
#
# Table name: steps
#
#  id           :integer          not null, primary key
#  step_type    :integer          default("normal")
#  name         :string(255)
#  description  :text(65535)
#  workflow_id  :integer
#  next_step_id :integer
#  fail_step_id :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  owner_type   :integer          default("any_owner")
#

class Step < ApplicationRecord
   enum step_type: [:start, :end, :error, :normal]
   enum owner_type: [:any_owner, :prior_owner, :unique_owner, :original_owner, :supervisor_owner]

   validates :name, :presence => true

   belongs_to :workflow
   belongs_to :next_step, class_name: "Step", optional: true
   belongs_to :fail_step, class_name: "Step", optional: true
   has_many :notes
end
