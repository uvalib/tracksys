class Category < ActiveRecord::Base
   validates :name, presence: true, uniqueness: true
end
