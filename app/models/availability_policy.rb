class AvailabilityPolicy < ActiveRecord::Base
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
  validates :name, :xacml_policy_url, :presence => true, :uniqueness => true
  validates :xacml_policy_url, :format => {:with => URI::regexp(['http','https'])}

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------
  def xacml_policy_url
    return "#{self.repository_url}/fedora/objects/#{self.pid}/datastreams/XACML/content"
  end
end

# == Schema Information
#
# Table name: availability_policies
#
#  id                 :integer          not null, primary key
#  name               :string(255)
#  bibls_count        :integer          default(0)
#  components_count   :integer          default(0)
#  master_files_count :integer          default(0)
#  units_count        :integer          default(0)
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  repository_url     :string(255)
#  pid                :string(255)
#
