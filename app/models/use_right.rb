class UseRight < ActiveRecord::Base
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
  validates :description, :name, :presence => true
  validates :name, :uniqueness => true

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
