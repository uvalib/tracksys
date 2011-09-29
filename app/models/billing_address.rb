# == Schema Information
#
# Table name: billing_addresses
#
#  id           :integer         not null, primary key
#  customer_id  :integer
#  agency_id    :integer
#  last_name    :string(255)
#  first_name   :string(255)
#  address_1    :string(255)
#  address_2    :string(255)
#  city         :string(255)
#  state        :string(255)
#  country      :string(255)
#  post_code    :string(255)
#  phone        :string(255)
#  organization :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#

require "#{Hydraulics.models_dir}/billing_address"

class BillingAddress
end
