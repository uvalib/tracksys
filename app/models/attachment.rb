# == Schema Information
#
# Table name: attachments
#
#  id          :integer          not null, primary key
#  unit_id     :integer
#  filename    :string(255)
#  md5         :string(255)
#  description :text(65535)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Attachment < ActiveRecord::Base
  belongs_to :unit
end
