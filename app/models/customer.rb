class Customer < ActiveRecord::Base
   include Rails.application.routes.url_helpers # neeeded for _path helpers to work in models

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :academic_status, :counter_cache => true
   belongs_to :department, :counter_cache => true

   has_many :orders, :inverse_of => :customer
   has_many :requests, ->{ where('orders.order_status = ?', 'requested')}, :inverse_of => :customer
   has_many :units, :through => :orders
   has_many :master_files, :through => :units
   has_many :metadata, ->{ uniq }, :through => :units
   has_many :invoices, :through => :orders
   has_many :agencies, ->{ uniq }, :through => :orders

   has_one :primary_address, ->{ where(address_type: 'primary')}, :class_name => 'Address', :as => :addressable, :dependent => :destroy, :autosave => true
   has_one :billable_address, ->{ where(address_type: 'billable_address')}, :class_name => 'Address', :as => :addressable, :dependent => :destroy, :autosave => true

   accepts_nested_attributes_for :primary_address, :update_only => true
   accepts_nested_attributes_for :billable_address, :reject_if => :all_blank
   accepts_nested_attributes_for :orders
   accepts_nested_attributes_for :primary_address
   accepts_nested_attributes_for :billable_address, :reject_if => :all_blank

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :last_name, :first_name, :email, :presence => {
      :message => 'is required.'
   }
   validates :email, :uniqueness => true

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   default_scope {order('last_name ASC, first_name ASC')}
   scope :has_unpaid_invoices, lambda{ where('customers.id > 0').joins(:orders).joins(:invoices).where('invoices.date_fee_paid' => nil).where('orders.fee_actual > 0').uniq }

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------

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

   alias_attribute :name, :full_name

   def agency_links
      return ""  if agencies.empty?
      out = ""
      self.agencies.sort_by(&:name).each do |agency|
         out << "<div><a href='/admin/agencies/#{agency.id}'>#{agency.name}</a></div>"
      end
      return out
   end

end

# == Schema Information
#
# Table name: customers
#
#  id                 :integer          not null, primary key
#  department_id      :integer
#  academic_status_id :integer          default(0), not null
#  last_name          :string(255)
#  first_name         :string(255)
#  email              :string(255)
#  created_at         :datetime
#  updated_at         :datetime
#  master_files_count :integer          default(0)
#  orders_count       :integer          default(0)
#
