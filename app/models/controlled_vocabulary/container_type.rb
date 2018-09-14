# == Schema Information
#
# Table name: container_types
#
#  id          :bigint(8)        not null, primary key
#  name        :string(255)      not null
#  has_folders :boolean          default(FALSE)
#

class ContainerType < ApplicationRecord
   validates :name, presence: true
end
