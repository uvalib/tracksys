require "#{Hydraulics.models_dir}/archive"

class Archive
  default_scope :order => :name
end
# == Schema Information
#
# Table name: archives
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  description :string(255)
#  units_count :integer(4)      default(0)
#  directory   :string(255)
#

