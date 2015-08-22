require "#{Hydraulics.models_dir}/use_right"

class UseRight
end
# == Schema Information
#
# Table name: use_rights
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  description        :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  bibls_count        :integer(4)      default(0)
#  components_count   :integer(4)      default(0)
#  master_files_count :integer(4)      default(0)
#  units_count        :integer(4)      default(0)
#

