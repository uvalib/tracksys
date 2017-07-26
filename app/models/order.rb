require 'prawn'
require 'prawn/table'

class Order < ApplicationRecord

   ORDER_STATUSES = ['requested', 'deferred', 'canceled', 'approved', 'completed', 'awaiting_fee_approval']
   include BuildOrderPDF

   def as_json(options)
      super(:except => [:email])
   end

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :agency, counter_cache: true, optional: true
   belongs_to :customer, counter_cache: true, :inverse_of => :orders

   has_many :job_statuses, :as => :originator, :dependent => :destroy
   has_many :audit_events, :as=> :auditable, :dependent => :destroy
   has_many :invoices, :dependent => :destroy
   has_many :units, :inverse_of => :order

   has_many :sirsi_metadata, ->{ where(type: "SirsiMetadata") }, :through => :units, :source=>:metadata
   has_many :xml_metadata, ->{where(type: "XmlMetadata") }, :through => :units, :source=>:metadata
   has_many :master_files, :through => :units
   has_many :projects, :through=> :units

   has_one :academic_status, :through => :customer
   has_one :department, :through => :customer
   has_one :primary_address, :through => :customer
   has_one :billable_address, :through => :customer

   accepts_nested_attributes_for :units
   accepts_nested_attributes_for :customer

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :complete, ->{ where("order_status = 'completed' or date_archiving_complete is not null") }
   scope :deferred, ->{where("order_status = 'deferred'") }
   scope :in_process, ->{where("order_status = 'approved'") }
   scope :awaiting_approval, ->{where("order_status = 'requested' or order_status = 'awaiting_fee_approval'") }
   scope :ready_for_delivery, ->{ where("`orders`.email is not null").where(:date_customer_notified => nil) }
   scope :recent, lambda{ |limit=5| order('date_request_submitted DESC').limit(limit) }
   scope :unpaid, ->{ where("fee_actual > 0").joins(:invoices).where('`invoices`.date_fee_paid IS NULL').where('`invoices`.permanent_nonpayment IS false').where('`orders`.date_customer_notified > ?', 2.year.ago).order('fee_actual desc') }
   scope :patron_requests, ->{joins(:units).where('units.intended_use_id != 110').distinct.order(id: :asc)}

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :date_due, :date_request_submitted, :presence => {
      :message => 'is required.'
   }

   validates :order_title, :uniqueness => true, :allow_blank => true

   validates :fee_estimated, :fee_actual, :numericality => {:greater_than_or_equal_to => 0, :allow_nil => true}

   validates :order_status, :inclusion => { :in => ORDER_STATUSES,
      :message => 'must be one of these values: ' + ORDER_STATUSES.join(", ")}

   # validates that an order_status cannot equal approved if any of it's Units.unit_status != "approved" || "canceled"
   validate :validate_order_approval, :on => :update, :if => 'self.order_status == "approved"'

   #------------------------------------------------------------------
   # callbacks
   #------------------------------------------------------------------

   before_save do
      # boolean fields cannot be NULL at database level
      self.is_approved = 0 if self.is_approved.nil?
      self.is_approved = 1 if self.order_status == 'approved'
      self.email = nil if self.email.blank?
      if self.projects.count > 0
         self.projects.update_all(due_on: self.date_due)
      end
      if self.order_status == 'canceled' && self.units.count > 0
         self.units.update_all(unit_status: 'canceled')
      end
   end

   before_destroy :destroyable?
   def destroyable?
      if self.units.size > 0 || self.invoices.size > 0
         errors[:base] << "cannot delete order that is associated with invoices or units"
         return false
      end
      return true
   end

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   def active?
      return !(order_status == 'canceled' || order_status == 'deferred'||  order_status == 'completed')
   end

   def reorder?
      self.units.each do |u|
         return true if u.reorder
      end
      return false
   end
   def all_reorders_ready?
      self.units.each do |u|
         return false if !u.reorder
      end
      return true
   end

   # Returns a boolean value indicating whether the Order is approved
   # for digitization ("order") or not ("request").
   def approved?
      return order_status == 'approved'
   end

   def canceled?
      return if order_status == 'canceled'
   end

   # Returns a boolean value indicating whether this Order has
   # associated Invoice records.
   def invoices?
      return invoices.any?
   end

   def last_error
      js = self.job_statuses.order(created_at: :desc).first
      if !js.nil? && js.status == 'failure'
         return {job: js[:id], error: js[:error] }
      end
      self.units.each do |u|
         err = u.last_error
         return err if !err.nil?
      end
      return nil
   end

   # Returns units belonging to current order that are not ready to proceed with digitization and would prevent an order from being approved.
   # Only units whose unit_status = 'approved' or 'canceled' are removed from consideration by this method.
   def has_units_being_prepared
      units_beings_prepared = Unit.where(:order_id => self.id).where('unit_status = "unapproved" or unit_status = "condition" or unit_status = "copyright"')
      return units_beings_prepared
   end

   # A validation callback which returns to the Order#edit view the IDs of Units which are preventing the Order from being approved because they
   # are neither approved or canceled.
   def validate_order_approval
      units_beings_prepared = self.has_units_being_prepared
      if not units_beings_prepared.empty?
         errors[:order_status] << "cannot be set to approved because units #{units_beings_prepared.map(&:id).join(', ')} are neither approved nor canceled"
      end
   end

   def self.due_today()
      Order.due_within(0.day.from_now)
   end
   def self.due_in_a_week()
      Order.due_within(1.week.from_now)
   end
   def self.due_within(timespan)
      if ! timespan.kind_of?(ActiveSupport::TimeWithZone)
         logger.error "#{self.name}#due_within expecting ActiveSupport::TimeWithZone as argument.  Got #{timespan.class} instead"
         timespan = 1.week.from_now
      end
      q = nil
      if Time.now.to_date == timespan.to_date
         where("date_due = ?", Date.today).active.patron_requests
      elsif Time.now > timespan
         where("date_due < ?", Date.today).where("date_due > ?", timespan).active.patron_requests
      else
         where("date_due > ?", Date.today).where("date_due < ?", timespan).active.patron_requests
      end
   end
   def self.overdue
      date=0.days.ago
      where("date_request_submitted > ?", date - 1.years ).where("date_due < ?", date).active
   end
   def self.active
      where("order_status != ? and order_status != ?", "completed", "deferred")
   end

   def title
      return self.order_title if !self.order_title.blank?
      return self.sirsi_metadata.first.title if !self.sirsi_metadata.blank?
      return self.xml_metadata.first.title if !self.xml_metadata.blank?
      return nil
   end

   def complete_order
      if has_patron_deliverables?
         # validate that the order has date customer notified set
         if !date_customer_notified.nil?
            update(order_status: "completed", date_completed: Time.now)
            return true
         else
            if date_patron_deliverables_complete.nil?
               errors.add(:customer, "deliverables have not been generated")
            else
               errors.add(:customer, "has not been notified")
            end
         end
      else
         # validate that date archived set
         if !date_archiving_complete.nil?
            update(order_status: "completed", date_completed: Time.now)
            return true
         else
            if date_finalization_begun.nil?
               errors.add(:order, "has not been finalized")
            else
               errors.add(:order, "has not been archived")
            end
         end
      end
      return false
   end

   def defer_order
      # entering a deferred state or leaving it?
      if self.order_status != 'deferred'
         self.order_status = 'deferred'
         self.date_deferred = Time.now
         self.save!
      else
         # resuming a deferred order
         if self.date_order_approved.nil?
            update(order_status: "requested")
         else
            update(order_status: "approved")
         end
      end
   end

   def approve_order
      self.order_status = 'approved'
      self.date_order_approved = Time.now
      self.save!
   end

   def cancel_order
      self.order_status = 'canceled'
      self.date_canceled = Time.now
      self.save!
   end

   def has_patron_deliverables?
      self.units.each do |u|
         # only units that are NOT for digital collection building can have patron deliverables
         if !u.intended_use.nil? && u.intended_use.description != "Digital Collection Building"
            return true if u.include_in_dl == false   # this has a patron deliverable
            return true if u.include_in_dl == true &&  u.metadata.availability_policy_id? # DL and Patron deliverables
         end
      end
      return false
   end

   def generate_notice
       generate_invoice_pdf(self, self.fee_actual)
   end

   def self.upaid_customer_report
      p = Axlsx::Package.new
      p.use_shared_strings = true
      cids = []
      p.workbook do |wb|
         wb.add_worksheet(:name => "Customers with unpaid orders") do |sheet|
            row_number = 2 # Since title row is 1, we start at 2.
            sheet.add_row ['Name', 'Email', 'Primary Phone', 'Primary Address', 'Billable Phone', 'Billable Address']
            self.unpaid.each do |unpaid|
               c = unpaid.customer
               next if cids.include? c.id
               cids << c.id
               row = []
               row << c.full_name
               row << c.email
               pa = c.primary_address
               if pa.nil?
                  row << "N/A"
                  row << "N/A"
               else
                  row << pa.phone if !pa.phone.blank?
                  row << "N/A" if pa.phone.blank?
                  if pa.address_1.nil?
                     row << "N/A"
                  else
                     row << pa.short_format
                  end
               end
               ba = c.billable_address
               if ba.nil?
                  row << "N/A"
                  row << "N/A"
               else
                  row << ba.phone if !ba.phone.blank?
                  row << "N/A" if ba.phone.blank?
                  if ba.address_1.nil?
                     row << "N/A"
                  else
                     row << ba.short_format
                  end
               end
               row = sheet.add_row row
            end
         end
      end
      p.use_autowidth = true
      file = Tempfile.new( ['unpaid', '.xlsx'] )
      file.write(p.to_stream.read)
      file.rewind
      file.close
      return file
   end
end

# == Schema Information
#
# Table name: orders
#
#  id                                 :integer          not null, primary key
#  customer_id                        :integer          default(0), not null
#  agency_id                          :integer
#  order_status                       :string(255)
#  is_approved                        :boolean          default(FALSE), not null
#  order_title                        :string(255)
#  date_request_submitted             :datetime
#  date_order_approved                :datetime
#  date_deferred                      :datetime
#  date_canceled                      :datetime
#  date_due                           :date
#  date_customer_notified             :datetime
#  fee_estimated                      :decimal(7, 2)
#  fee_actual                         :decimal(7, 2)
#  special_instructions               :text(65535)
#  created_at                         :datetime
#  updated_at                         :datetime
#  staff_notes                        :text(65535)
#  email                              :text(65535)
#  date_patron_deliverables_complete  :datetime
#  date_archiving_complete            :datetime
#  date_finalization_begun            :datetime
#  date_fee_estimate_sent_to_customer :datetime
#  units_count                        :integer          default(0)
#  invoices_count                     :integer          default(0)
#  master_files_count                 :integer          default(0)
#
