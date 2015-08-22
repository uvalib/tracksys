require "#{Hydraulics.models_dir}/checkin"

class Checkin

  after_update :fix_updated_counters
end
# == Schema Information
#
# Table name: checkins
#
#  id              :integer(4)      not null, primary key
#  unit_id         :integer(4)      default(0), not null
#  staff_member_id :integer(4)
#  created_at      :datetime
#  updated_at      :datetime
#

