# == Schema Information
#
# Table name: archives
#
#  id          :integer         not null, primary key
#  name        :string(255)
#  description :string(255)
#  units_count :integer         default(0)
#  created_at  :datetime
#  updated_at  :datetime
#

require "#{Hydraulics.models_dir}/archive"

class Archive
end
