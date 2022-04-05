# == Schema Information
#
# Table name: events
#
#  id              :integer          not null, primary key
#  job_status_id :integer
#  text            :text(65535)
#  level       :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class Event < ApplicationRecord
   enum level: [:info, :warning, :error, :fatal]
   belongs_to :job_status

   validates :job_status, presence: true
   validates :text, presence: true
   validates :level, presence: true
end
