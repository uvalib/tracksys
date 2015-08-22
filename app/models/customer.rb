require "#{Hydraulics.models_dir}/customer"

class Customer
  include Rails.application.routes.url_helpers # neeeded for _path helpers to work in models
  accepts_nested_attributes_for :primary_address
  accepts_nested_attributes_for :billable_address, :reject_if => :all_blank

  after_update :fix_updated_counters
  
  has_paper_trail

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
  scope :has_unpaid_invoices, lambda{ where('customers.id > 0').joins(:orders).joins(:invoices).where('invoices.date_fee_paid' => nil).where('orders.fee_actual > 0').uniq }
 
  #------------------------------------------------------------------
  # public class methods
  #------------------------------------------------------------------
 
  #------------------------------------------------------------------
  # public instance methods
  #------------------------------------------------------------------
  def external?
    # if the customer is Non-UVA (academic_status.id = 1)
    if self.academic_status_id == 1 
      return true
    else
      return false
    end
  end

  def admin_permalink
    admin_customer_path(self)
  end

  alias_attribute :name, :full_name

end
# == Schema Information
#
# Table name: customers
#
#  id                     :integer(4)      not null, primary key
#  department_id          :integer(4)
#  academic_status_id     :integer(4)      default(0), not null
#  heard_about_service_id :integer(4)
#  last_name              :string(255)
#  first_name             :string(255)
#  email                  :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  master_files_count     :integer(4)      default(0)
#  orders_count           :integer(4)      default(0)
#

