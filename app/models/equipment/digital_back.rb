# == Schema Information
#
# Table name: equipment
#
#  id            :integer          not null, primary key
#  type          :string(255)
#  name          :string(255)
#  serial_number :string(255)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  status        :integer          default(0)
#

class DigitalBack < Equipment
end
