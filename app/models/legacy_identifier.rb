class LegacyIdentifier < ActiveRecord::Base
  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_and_belongs_to_many :metadata
  has_and_belongs_to_many :components
  has_and_belongs_to_many :master_files
  has_and_belongs_to_many :units


  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------

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
  def destroyable?
    if self.master_files.empty? and self.components.empty? and self.bibls.empty?
      return true
    else
      return false
    end
  end
end

# == Schema Information
#
# Table name: legacy_identifiers
#
#  id                :integer          not null, primary key
#  label             :string(255)
#  description       :string(255)
#  legacy_identifier :string(255)
#  created_at        :datetime
#  updated_at        :datetime
#
