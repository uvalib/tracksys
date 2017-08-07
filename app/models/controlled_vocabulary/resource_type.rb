# == Schema Information
#
# Table name: resource_types
#
#  id   :integer          not null, primary key
#  name :string(255)
#

class ResourceType < ApplicationRecord
   validates :name, presence: true
end
