# == Schema Information
#
# Table name: preservation_tiers
#
#  id          :bigint(8)        not null, primary key
#  name        :string(255)
#  description :string(255)
#

class PreservationTier < ApplicationRecord
   validates :name, :uniqueness => true, :presence => true
   validates :description, :presence => true
end
