# SqlReport represents a SQL query with a name and description, saved to the
# database for repeated use.
class SqlReport < ActiveRecord::Base

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :name, :sql, :presence => true
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
  # Returns a string containing a brief, general description of this class/model.
  def self.class_description
    return "Custom Report is a SQL query with a name and description, saved to the database for repeated use."
  end

  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------

end

# == Schema Information
#
# Table name: sql_reports
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :string(255)
#  sql         :text(65535)
#  created_at  :datetime
#  updated_at  :datetime
#
