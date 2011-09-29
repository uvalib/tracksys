# == Schema Information
#
# Table name: automation_messages
#
#  id             :integer         not null, primary key
#  unit_id        :integer
#  order_id       :integer
#  master_file_id :integer
#  bibl_id        :integer
#  ead_ref_id     :integer
#  component_id   :integer
#  active_error   :boolean         default(FALSE), not null
#  pid            :string(255)
#  app            :string(255)
#  processor      :string(255)
#  message_type   :string(255)
#  workflow_type  :string(255)
#  message        :text
#  class_name     :text
#  backtrace      :text
#  created_at     :datetime
#  updated_at     :datetime
#

require "#{Hydraulics.models_dir}/automation_message"

class AutomationMessage
  APPS = APPS + %w[tracksys]
end
