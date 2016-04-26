class IndexingScenario < ActiveRecord::Base

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :bibls
  has_many :components
  has_many :master_files
  has_many :units

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :name, :pid, :repository_url, :datastream_name, :presence => true
  validates :name, :pid, :uniqueness => true
  validates :repository_url, :format => {:with => URI::regexp(['http','https'])}

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------
  default_scope { order('name') }

  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------
  def complete_url
    return "#{self.repository_url}/fedora/objects/#{self.pid}/datastreams/#{self.datastream_name}/content"
  end

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
