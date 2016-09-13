class Address < ActiveRecord::Base
  belongs_to :addressable, :polymorphic => true

  # validates :customer_id, :agency_id, :uniqueness => true
  validates :address_1, :country, :city, :presence => {
    :message => 'is required.'
  }
end

# == Schema Information
#
# Table name: addresses
#
#  id               :integer          not null, primary key
#  addressable_id   :integer          not null
#  addressable_type :string(20)       not null
#  address_type     :string(20)       not null
#  last_name        :string(255)
#  first_name       :string(255)
#  address_1        :string(255)
#  address_2        :string(255)
#  city             :string(255)
#  state            :string(255)
#  country          :string(255)
#  post_code        :string(255)
#  phone            :string(255)
#  organization     :string(255)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
