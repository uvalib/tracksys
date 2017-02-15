class Equipment < ActiveRecord::Base
   validates :name, presence: true
   validates :serial_number, presence: true, uniqueness: true
end
