# == Schema Information
#
# Table name: staff_members
#
#  id           :integer          not null, primary key
#  computing_id :string(255)
#  last_name    :string(255)
#  first_name   :string(255)
#  is_active    :boolean          default(FALSE), not null
#  created_at   :datetime
#  updated_at   :datetime
#  email        :string(255)
#  role         :integer          default("admin")
#  notes        :text(65535)
#

class StaffMember < ApplicationRecord
   enum role: [:admin, :supervisor, :student, :viewer]

   has_and_belongs_to_many :skills, :join_table=>:staff_skills, :class_name=>"Category"

   has_many :job_statuses, :as => :originator, :dependent => :destroy
   validates :computing_id, :presence => true, :uniqueness => {:case_sensitive => false}

   has_many :projects, foreign_key: 'owner_id'
   has_many :messages, foreign_key: 'to_id',   :class_name => 'Message'
   has_many :sent_messages, foreign_key: 'from_id',   :class_name => 'Message'

   public
   def has_unread_messages?
      return self.messages.where(read: 0).count > 0
   end
   def unread_message_cnt
      return self.messages.where(read: 0).count
   end
   def first_unread_message
       return self.messages.where(read: 0).first
   end
   def sent_messages
      return self.sent_messages.where(deleted: 0)
   end

   def can_deaccession?
      return DEACCESSION_USERS.include? self.computing_id
   end

   def can_process? ( category)
      return self.skills.include?(category) || self.admin? || self.supervisor?
   end

   def self.candidates_for ( category )
      join = "inner join staff_skills s on s.staff_member_id=staff_members.id"
      return StaffMember.joins(join)
         .where("(role <= 1 and is_active=1) or (s.category_id=? and role=2 and is_active=1)", category.id)
         .distinct.order(last_name: :asc)
   end

   # Returns a boolean value indicating whether the StaffMember is
   # active.
   def active?
      if is_active
         return true
      else
         return false
      end
   end

   def full_name
      [first_name, last_name].join(' ')
   end

   # Returns a string containing the label that identifies this
   # particular object -- the UVA computing ID of this StaffMember.
   def label
      return computing_id
   end


   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------

   # Active Record callback; gets called before saving record to database
   def before_save
      # boolean fields cannot be NULL at database level
      self.is_active = 0 if self.is_active.nil?
   end

   alias_attribute :name, :full_name

end
