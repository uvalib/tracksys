# == Schema Information
#
# Table name: agencies
#
#  id           :integer         not null, primary key
#  name         :string(255)
#  description  :string(255)
#  is_billable  :boolean         default(FALSE), not null
#  last_name    :string(255)
#  first_name   :string(255)
#  address_1    :string(255)
#  address_2    :string(255)
#  city         :string(255)
#  state        :string(255)
#  country      :string(255)
#  post_code    :string(255)
#  phone        :string(255)
#  orders_count :integer         default(0)
#  created_at   :datetime
#  updated_at   :datetime
#

require "#{Hydraulics.models_dir}/agency"

class Agency
end
