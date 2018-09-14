# == Schema Information
#
# Table name: external_systems
#
#  id         :bigint(8)        not null, primary key
#  name       :string(255)
#  public_url :string(255)
#  api_url    :string(255)
#

class ExternalSystem < ApplicationRecord
   validates :name, presence: true, uniqueness: true
   validates :public_url, presence: true
end
