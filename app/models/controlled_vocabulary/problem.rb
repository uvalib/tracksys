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
   def self.qa
      out = Problem.where("not(id >= 5 and id <= 7) and id < 11").order(name: :asc).to_a
      out << Problem.find_by(name: "Other")
      return out
   end
end
