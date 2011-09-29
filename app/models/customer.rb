# == Schema Information
#
# Table name: customers
#
#  id                     :integer         not null, primary key
#  heard_about_service_id :integer
#  last_name              :string(255)
#  first_name             :string(255)
#  address_1              :string(255)
#  address_2              :string(255)
#  city                   :string(255)
#  state                  :string(255)
#  country                :string(255)
#  post_code              :string(255)
#  phone                  :string(255)
#  email                  :string(255)
#  organization           :string(255)
#  orders_count           :integer         default(0)
#  created_at             :datetime
#  updated_at             :datetime
#

require "#{Hydraulics.models_dir}/customer"

class Customer

  # validates :uva_status, 
  #           :presence => true, 
  #           :message => "The 'UVa Status' associated with this Customer no longer exists."

end
