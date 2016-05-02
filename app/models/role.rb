# == Schema Information
#
# Table name: roles
#
#  id   :integer          not null, primary key
#  name :string(255)      not null
#

class Role < ActiveRecord::Base
   validates :name, :presence => true, :uniqueness => {:case_sensitive => false}
end
