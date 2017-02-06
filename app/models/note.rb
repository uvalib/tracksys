class Note < ActiveRecord::Base
   enum note_type: [:comment, :suggestion, :problem, :item_condition]
   belongs_to :staff_member
   belongs_to :problem
   belongs_to :task

   validates :task, presence: true
   validates :staff_member, presence: true
   validates :note_type, presence: true
   validates :note, presence: true
end
