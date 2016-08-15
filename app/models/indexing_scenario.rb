class IndexingScenario < ActiveRecord::Base

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :metadata, :source=>:metadata, :class_name => 'Metadata'
  has_many :components
  has_many :master_files
  has_many :units

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------
  default_scope { order('name') }
end

# == Schema Information
#
# Table name: indexing_scenarios
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  metadata_count     :integer          default(0)
#  components_count   :integer          default(0)
#  master_files_count :integer          default(0)
#  units_count        :integer          default(0)
#
