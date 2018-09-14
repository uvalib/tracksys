# == Schema Information
#
# Table name: notes
#
#  id              :integer          not null, primary key
#  staff_member_id :integer
#  project_id      :integer
#  note            :text(65535)
#  note_type       :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  step_id         :integer
#

class Note < ApplicationRecord
   enum note_type: [:comment, :suggestion, :problem, :item_condition]
   belongs_to :staff_member
   has_and_belongs_to_many :problems
   belongs_to :project
   belongs_to :step

   validates :project, presence: true
   validates :staff_member, presence: true
   validates :note_type, presence: true
   validates :note, presence: true
end
