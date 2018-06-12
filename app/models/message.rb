class Message < ApplicationRecord
   belongs_to :to, class_name: "StaffMember", foreign_key: "to_id"
   belongs_to :from, class_name: "StaffMember", foreign_key: "from_id"

   validates :to, presence: true
   validates :from, presence: true
   validates :message, presence: true

   default_scope { order(sent_at: :desc) }
end
