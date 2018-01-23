class Checkout < ApplicationRecord
   belongs_to :metadata
   validates :checkout_date, presence: true
end
