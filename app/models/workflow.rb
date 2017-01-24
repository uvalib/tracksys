class Workflow < ActiveRecord::Base
   validates :name, :uniqueness => true, :presence => true
   has_many :steps
end
