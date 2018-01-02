class OrderItem < ApplicationRecord
   belongs_to :order
   belongs_to :intended_use
end
