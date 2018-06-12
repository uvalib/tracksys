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
#  role         :integer          default(0)
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

   # Returns a string containing the StaffMember name to be displayed
   # in "list" views, drop-down menus, etc.: the first name and last
   # name as formatted by the +name+ method, followed by the UVA
   # computing ID in parentheses.
   def list_name(alpha = false)
      out = name(alpha)
      if out.blank?
         out = computing_id.to_s
      else
         if not computing_id.blank?
            out += ' (' + computing_id + ')'
         end
      end
      return out
   end

   # Same as +list_name+ but formats StaffMember name for alphabetic
   # sorting as "last-name, first-name".
   #
   # Useful with +collection_select+ where you can't call
   # <tt>list_name(true)</tt>. Example:
   #   collection_select :task, :staff_member_id, @staff_members, :id, :list_name_alpha
   def list_name_alpha
      return list_name(true)
   end

   # Returns a string: the first name, if available; otherwise the
   # UVA computing ID (which is required and thus always available).
   def salutation
      if not first_name.blank?
         return first_name
      else
         return computing_id
      end
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
