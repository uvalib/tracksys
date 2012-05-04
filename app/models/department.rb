require "#{Hydraulics.models_dir}/department"

class Department
  default_scope :order => :name
end
