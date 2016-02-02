class HeardAboutService < ActiveRecord::Base

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
  has_many :customers
  has_many :orders, :through => :customers
  has_many :units, :through => :orders
  has_many :master_files, :through => :units

  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # callbacks
  #------------------------------------------------------------------
  before_save do
    self.is_approved = 0 if self.is_approved.nil?
    self.is_internal_use_only = 0 if self.is_internal_use_only.nil?
  end

  #------------------------------------------------------------------
  # scopes
  #------------------------------------------------------------------
  scope :approved, where(:is_approved => true)
  scope :not_approved, where(:is_approved => false)
  scope :internal_use_only, where(:is_internal_use_only => true)
  scope :publicly_available, where(:is_internal_use_only => false)
  default_scope :order => :description
  scope :for_request_form, where(:is_approved => true).where(:is_internal_use_only => false)
  
  #------------------------------------------------------------------
  # aliases
  #------------------------------------------------------------------
  # Necessary for Active Admin to poplulate pulldown menu
  alias_attribute :name, :description

  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------

  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------

end

# == Schema Information
#
# Table name: heard_about_services
#
#  id                   :integer(4)      not null, primary key
#  description          :string(255)
#  created_at           :datetime
#  updated_at           :datetime
#  is_approved          :boolean(1)      default(FALSE), not null
#  is_internal_use_only :boolean(1)      default(FALSE), not null
#  customers_count      :integer(4)      default(0)
#
