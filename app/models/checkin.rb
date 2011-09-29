# == Schema Information
#
# Table name: checkins
#
#  id            :integer         not null, primary key
#  unit_id       :integer
#  admin_user_id :integer
#  units_count   :integer         default(0)
#  created_at    :datetime
#  updated_at    :datetime
#

require "#{Hydraulics.models_dir}/checkin"

class Checkin
end
