class ContainerType < ActiveRecord::Base

  has_many :containers

  validates :name, :presence => true

end
# == Schema Information
#
# Table name: container_types
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  description :string(255)
#
