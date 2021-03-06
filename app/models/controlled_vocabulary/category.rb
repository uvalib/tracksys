# == Schema Information
#
# Table name: categories
#
#  id             :integer          not null, primary key
#  name           :string(255)
#  projects_count :integer          default(0)
#

class Category < ApplicationRecord
   validates :name, presence: true, uniqueness: true
end
