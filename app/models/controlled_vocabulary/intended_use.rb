class IntendedUse < ActiveRecord::Base
  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :units

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :description, :presence => true

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------
  scope :external_use, ->{ where(:is_internal_use_only => false).where(is_approved:1) }
  default_scope {order('description') }

  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------
  before_destroy :destroyable?

  before_save do
    # boolean fields cannot be NULL at database level
    self.is_internal_use_only = 0 if self.is_internal_use_only.nil?
    self.is_approved = 0          if self.is_approved.nil?
  end

  def name
     res = "#{self.deliverable_resolution} DPI"
     res = "highest possible resolution" if self.deliverable_resolution == "Highest Possible" || self.deliverable_resolution.blank?
     fmt = self.deliverable_format
     fmt = "tif" if fmt.blank?
     return "#{self.description} : #{res} #{fmt}"
  end

  # Returns a boolean value indicating whether it is safe to delete this record
  # from the database. Returns +false+ if this record has dependent records in
  # other tables, namely associated Unit records.
  #
  # This method is public but is also called as a +before_destroy+ callback.
  def destroyable?
    if self.units.size > 0
      return false
    end
    return true
  end

end

# == Schema Information
#
# Table name: intended_uses
#
#  id                          :integer          not null, primary key
#  description                 :string(255)
#  is_internal_use_only        :boolean          default(FALSE), not null
#  is_approved                 :boolean          default(FALSE), not null
#  created_at                  :datetime
#  updated_at                  :datetime
#  units_count                 :integer          default(0)
#  deliverable_format          :string(255)
#  deliverable_resolution      :string(255)
#
