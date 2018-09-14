# == Schema Information
#
# Table name: messages
#
#  id         :bigint(8)        not null, primary key
#  subject    :string(255)      not null
#  message    :text(65535)
#  read       :boolean          default(FALSE)
#  from_id    :bigint(8)
#  to_id      :bigint(8)
#  sent_at    :datetime         not null
#  deleted    :boolean          default(FALSE)
#  deleted_at :datetime
#

class Message < ApplicationRecord
   belongs_to :to, class_name: "StaffMember", foreign_key: "to_id"
   belongs_to :from, class_name: "StaffMember", foreign_key: "from_id"

   validates :to, presence: true
   validates :from, presence: true
   validates :message, presence: true

   default_scope { order(sent_at: :desc) }

   # remove any messages that have been flagged as deleted after twp weeks
   #
   def self.remove_deleted
      deleted = Message.where('deleted=? and deleted_at < ?', 1, Date.today-2.weeks)
      if deleted.count > 0
         puts "Remove #{deleted.count} deleted messages"
         deleted.destroy_all
      end
   end
end
