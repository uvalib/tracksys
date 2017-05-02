class IndexingScenario < ActiveRecord::Base

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :metadata, :source=>:metadata, :class_name => 'Metadata'
  has_many :components
end

# == Schema Information
#
# Table name: indexing_scenarios
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  created_at       :datetime
#  updated_at       :datetime
#  metadata_count   :integer          default(0)
#  components_count :integer          default(0)
#
