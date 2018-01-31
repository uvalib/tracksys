class Checkout < ApplicationRecord
   belongs_to :metadata
   validates :checkout_at, presence: true
end
