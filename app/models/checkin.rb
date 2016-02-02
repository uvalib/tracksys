class Checkin < ActiveRecord::Base

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  belongs_to :unit, :counter_cache => true
  belongs_to :admin_user

  #------------------------------------------------------------------
  # validation
  #------------------------------------------------------------------
  validates :unit, :presence => {
              :if => 'self.unit_id',
              :message => "association with this Unit is no longer valid because the Unit object no longer exists."
            }
  validates :admin_user, :presence => {
              :if => 'self.admin_user_id',
              :message => "association with this User is no longer valid because the User object no longer exists."
            }

  after_update :fix_updated_counters
  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------

  # Returns a string containing a brief, general description of this
  # class/model.
  def Checkin.class_description
    return ''
  end
end
# == Schema Information
#
# Table name: checkins
#
#  id              :integer(4)      not null, primary key
#  unit_id         :integer(4)      default(0), not null
#  staff_member_id :integer(4)
#  created_at      :datetime
#  updated_at      :datetime
#
