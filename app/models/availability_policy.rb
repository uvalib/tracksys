class AvailabilityPolicy < ActiveRecord::Base
  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :bibls
  has_many :xml_metadata, class_name: "XmlMetadata"
  has_many :components
  has_many :master_files
  has_many :units

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :name, :presence => true, :uniqueness => true

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------
  after_create do
     update_attribute(:pid, "tsa:#{self.id}")
  end

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------
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
