class AvailabilityPolicy < ActiveRecord::Base
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
#  id             :integer          not null, primary key
#  name           :string(255)
#  metadata_count :integer          default(0)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  pid            :string(255)
#
