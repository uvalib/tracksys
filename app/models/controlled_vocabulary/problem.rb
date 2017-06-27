# == Schema Information
#
# Table name: problems
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  notes_count :integer          default(0)
#

class Problem < ApplicationRecord
   validates :name, :uniqueness => true, :presence => true
end
