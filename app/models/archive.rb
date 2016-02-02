class Archive < ActiveRecord::Base
  default_scope :order => :name
  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :units
  has_many :master_files, :through => :units

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :name, :presence => true, :uniqueness => {:case_sensitive => false} # 'HSM' and 'Hsm' should be considered the same.

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------
  before_destroy :destroyable?

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------
  # Returns a string containing a brief, general description of this
  # class/model.
  def Archive.class_description
    return 'Archive indicates the long-term storage location of a Unit.'
  end

  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------
  # Returns a boolean value indicating whether it is safe to delete
   # this Archive from the database. Returns +false+ if this record
   # has dependent records in other tables, namely associated Unit
   # records.
   #
   # This method is public but is also called as a +before_destroy+ callback.
   def destroyable?
     return false unless units.any?
   end
end

# == Schema Information
#
# Table name: archives
#
#  id          :integer(4)      not null, primary key
#  name        :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  description :string(255)
#  units_count :integer(4)      default(0)
#  directory   :string(255)
#
