require "#{Hydraulics.models_dir}/indexing_scenario"

class IndexingScenario
  default_scope :order => :name
end
# == Schema Information
#
# Table name: indexing_scenarios
#
#  id                 :integer(4)      not null, primary key
#  name               :string(255)
#  pid                :string(255)
#  datastream_name    :string(255)
#  repository_url     :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  bibls_count        :integer(4)      default(0)
#  components_count   :integer(4)      default(0)
#  master_files_count :integer(4)      default(0)
#  units_count        :integer(4)      default(0)
#

