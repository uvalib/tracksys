# == Schema Information
#
# Table name: genres
#
#  id   :integer          not null, primary key
#  name :string(255)
#

class Genre < ApplicationRecord
   validates :name, presence: true
end
