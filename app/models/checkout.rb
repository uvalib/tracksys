# == Schema Information
#
# Table name: checkouts
#
#  id          :bigint(8)        not null, primary key
#  metadata_id :bigint(8)
#  checkout_at :datetime
#  return_at   :datetime
#

class Checkout < ApplicationRecord
   belongs_to :metadata
   validates :checkout_at, presence: true
end
