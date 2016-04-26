class Customer < ActiveRecord::Base
   include Rails.application.routes.url_helpers # neeeded for _path helpers to work in models

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :academic_status, :counter_cache => true
   belongs_to :department, :counter_cache => true
   belongs_to :heard_about_service, :counter_cache => true

   has_many :orders, :inverse_of => :customer
   has_many :requests, ->{ where('orders.order_status = ?', 'requested')}, :inverse_of => :customer
   has_many :units, :through => :orders
   has_many :master_files, :through => :units
   has_many :bibls, ->{ uniq }, :through => :units
   has_many :invoices, :through => :orders
   has_many :agencies, ->{ uniq }, :through => :orders
   has_many :heard_about_resources, ->{ uniq }, :through => :orders

   has_one :primary_address, ->{ where(address_type: 'primary_address')}, :class_name => 'Address', :as => :addressable, :dependent => :destroy, :autosave => true
   has_one :billable_address, ->{ where(address_type: 'billable_address')}, :class_name => 'Address', :as => :addressable, :dependent => :destroy, :autosave => true

   accepts_nested_attributes_for :primary_address, :update_only => true
   accepts_nested_attributes_for :billable_address, :reject_if => :all_blank
   accepts_nested_attributes_for :orders
   accepts_nested_attributes_for :primary_address
   accepts_nested_attributes_for :billable_address, :reject_if => :all_blank

   delegate :organization,
   :to => :primary_address, :allow_nil => true, :prefix => true
   delegate :organization,
   :to => :billable_address, :allow_nil => true, :prefix => true

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :last_name, :first_name, :email, :presence => {
      :message => 'is required.'
   }
   validates :email, :uniqueness => true, :email => true # Email serves as a Customer object's unique identifier
   validates :last_name, :first_name, :person_name_format => true

   validates_presence_of :primary_address

   # Validating presence of continued association with valid external data
   validates :heard_about_service,
   :presence => {
      :if => 'self.heard_about_service_id',
      :message => "association with this Customer is no longer valid because the Heard About Service object does not exists."
   }

   validates :academic_status,
   :presence => {
      :if => 'self.academic_status_id',
      :message => "association with this Customer is no longer valid because the Academic Status object does not exists."
   }
   validates :department,
   :presence => {
      :if => 'self.department_id',
      :message => "association with this Customer is no longer valid because the Department object no longer exists."
   }
   validates :academic_status_id, :presence => true

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------
   before_destroy :destroyable?
   after_update :fix_updated_counters

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   default_scope {order('last_name ASC, first_name ASC')}
   scope :has_unpaid_invoices, lambda{ where('customers.id > 0').joins(:orders).joins(:invoices).where('invoices.date_fee_paid' => nil).where('orders.fee_actual > 0').uniq }


   #------------------------------------------------------------------
   # public class methods
   #------------------------------------------------------------------
   # Returns a string containing a brief, general description of this
   # class/model.
   def Customer.class_description
      return 'Customer represents a person with Requests and/or Orders for digitization.'
   end

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   # Returns a boolean value indicating whether it is safe to delete this
   # Customer from the database. Returns +false+ if this record has dependent
   # records in other tables, namely associated Order records. (We do not check
   # for a BillingAddress record, because it is considered merely an extension of
   # the Customer record; it gets destroyed when the Customer is destroyed.)
   #
   # This method is public but is also called as a +before_destroy+ callback.
   # def destroyable?
   def destroyable?
      if orders? || requests?
         return false
      else
         return true
      end
   end

   # Returns a boolean value indicating whether this Customer has
   # associated Order records.
   def orders?
      return false unless orders.any?
   end

   # Returns a boolean value indicating whether this Customer has
   # associated Request (unapproved Order) records.
   def requests?
      return false unless requests.any?
   end

   def full_name
      [first_name, last_name].join(' ')
   end

   alias_attribute :date_of_first_order, :created_at

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
