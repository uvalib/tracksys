require "#{Hydraulics.models_dir}/container"

class Container
end
# == Schema Information
#
# Table name: containers
#
#  id                  :integer(4)      not null, primary key
#  barcode             :string(255)
#  container_type      :string(255)
#  label               :string(255)
#  sequence_no         :string(255)
#  parent_container_id :integer(4)      default(0), not null
#  legacy_component_id :integer(4)      default(0), not null
#  created_at          :datetime
#  updated_at          :datetime
#  container_type_id   :integer(4)
#

