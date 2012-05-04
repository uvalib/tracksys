require "#{Hydraulics.models_dir}/customer"

class Customer
  accepts_nested_attributes_for :primary_address
  accepts_nested_attributes_for :billable_address, :reject_if => :all_blank

  after_update :fix_updated_counters

  #------------------------------------------------------------------
  # relationships
  #------------------------------------------------------------------
 
  #------------------------------------------------------------------
  # validations
  #------------------------------------------------------------------
  validates :academic_status_id, :presence => true
  # validates :academic_status, :presence => {
  #   :message => "association with this AcademicStatus is no longer valid because it no longer exists."
  # }
 
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

  alias_attribute :name, :full_name

end