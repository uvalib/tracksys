require "#{Hydraulics.models_dir}/department"

class Department
  default_scope :order => :name
end
# == Schema Information
#
# Table name: departments
#
#  id              :integer(4)      not null, primary key
#  name            :string(255)
#  created_at      :datetime
#  updated_at      :datetime
#  customers_count :integer(4)      default(0)
#

