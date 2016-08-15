class IndexingScenario < ActiveRecord::Base

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :metadata, :source=>:metadata, :class_name => 'Metadata'
  has_many :components
  has_many :master_files
  has_many :units

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :name, :pid, :repository_url, :datastream_name, :presence => true
  validates :name, :pid, :uniqueness => true

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------
  after_create do
     update_attribute(:pid, "tsi:#{self.id}")
  end

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
#  pid                :string(255)
#  datastream_name    :string(255)
#  repository_url     :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  metadata_count     :integer          default(0)
#  components_count   :integer          default(0)
#  master_files_count :integer          default(0)
#  units_count        :integer          default(0)
#
