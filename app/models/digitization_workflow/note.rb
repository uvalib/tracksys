class Note < ApplicationRecord
   enum note_type: [:comment, :suggestion, :problem, :item_condition]
   belongs_to :staff_member
   belongs_to :problem, counter_cache: true, optional: true
   belongs_to :project
   belongs_to :step

   validates :project, presence: true
   validates :staff_member, presence: true
   validates :note_type, presence: true
   validates :note, presence: true
end
