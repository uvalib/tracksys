require 'prawn'
require 'prawn/table'

class Order < ApplicationRecord

   ORDER_STATUSES = ['requested', 'deferred', 'canceled', 'approved', 'completed', 'await_fee']
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

   # These are the placeholder records received directly from the patron
   # order form. These are converted to units and discarded
   has_many :order_items

   accepts_nested_attributes_for :units
   accepts_nested_attributes_for :customer

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :active, ->{where("order_status != 'canceled' and order_status!='completed'") }
   scope :complete, ->{ where("order_status = 'completed' or date_archiving_complete is not null") }
   scope :deferred, ->{where("order_status = 'deferred'") }
   scope :in_process, ->{where("order_status = 'approved'") }
   scope :canceled, ->{where("order_status = 'canceled'") }
   scope :awaiting_approval, ->{where("order_status = 'requested' or order_status = 'await_fee'") }
   scope :ready_for_delivery, ->{ joins(:units).where("units.intended_use_id != 110")
      .where("orders.email is not null and order_status != 'canceled' and order_status != 'completed' and date_customer_notified is null")
      .distinct }
   scope :recent, lambda{ |limit=5| order('date_request_submitted DESC').limit(limit) }
   scope :unpaid, ->{ where("fee > 0").joins(:invoices).where('`invoices`.date_fee_paid IS NULL')
      .where('invoices.date_fee_declined is null')
      .where('`invoices`.permanent_nonpayment IS false').where('`orders`.date_customer_notified > ?', 2.year.ago)
      .where("order_status != ?", "canceled")
      .order('fee desc').distinct }
   scope :patron_requests, ->{joins(:units).where('units.intended_use_id != 110')
      .where("order_status != ?", "canceled")
      .distinct.order(id: :asc)}

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :date_due, :date_request_submitted, :presence => {
      :message => 'is required.'
   }

   validates :order_title, :uniqueness => true, :allow_blank => true
   validates :order_status, :inclusion => { :in => ORDER_STATUSES,
      :message => 'must be one of these values: ' + ORDER_STATUSES.join(", ")}

   # validates that an order_status cannot equal approved if any of it's Units.unit_status != "approved"
   validate :validate_order_approval, :on => :update

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

   def awaiting_approval?
      return (order_status == 'requested' || order_status == 'await_fee')
   end

   # Returns a boolean value indicating whether the Order is approved
   # for digitization ("order") or not ("request").
   def approved?
      return order_status == 'approved'
   end

   def in_progress?
      return order_status != "completed" && order_status != "deferred" && order_status != "canceled"
   end

   def canceled?
      return if order_status == 'canceled'
   end

   # Returns a boolean value indicating whether this Order has
   # associated Invoice records.
   def invoices?
      return invoices.any?
   end

   def fee_paid?
      return false if invoices.count == 0
      invoices.each do |inv|
         return true if !inv.date_fee_paid.blank?
      end
      return false
   end

   def fee_payment_info
      return nil if invoices.count == 0
      invoices.each do |inv|
         if !inv.date_fee_paid.blank?
            return {date_paid: inv.date_fee_paid, fee: inv.fee_amount_paid }
         end
      end
      return nil
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
   def unit_status_summary
      cnt_un = 0
      cnt_cr = 0
      cnt_cond = 0
      Unit.where(order_id: id).each do |u|
         cnt_un += 1 if u.unit_status == "unapproved"
         cnt_cr += 1 if u.unit_status == "copyright"
         cnt_cond += 1 if u.unit_status == "condition"
      end
      return "There are currently #{cnt_un} unapproved, #{cnt_cr} pending copyright review and #{cnt_cond} pending condition review."
   end

   def has_approved_units
      return Unit.where(:order_id => self.id).where('unit_status = "approved"').count > 0
   end

   # A validation callback which returns to the Order#edit view the IDs of Units which are preventing the Order from being approved because they
   # are neither approved or canceled.
   def validate_order_approval
      if order_status == "approved"
         if !has_approved_units
            errors[:order_status] << "cannot be set to approved because no units are approved"
         end
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
         where("date_due = ?", Date.today).in_progress.patron_requests
      else
         where("date_due >= ?", Date.today).where("date_due <= ?", timespan).in_progress.patron_requests
      end
   end

   def self.overdue
      date=0.days.ago
      where("date_request_submitted > ?", date - 1.years ).where("date_due < ?", date).in_progress
   end
   def self.in_progress
      where("order_status != ? and order_status != ? and order_status != ?",
         "completed", "deferred", "canceled")
   end

   def title
      return self.order_title if !self.order_title.blank?
      return self.sirsi_metadata.first.title if !self.sirsi_metadata.blank?
      return self.xml_metadata.first.title if !self.xml_metadata.blank?
      return nil
   end

   def complete_order(user)
      if has_patron_deliverables?
         # validate that the order has date customer notified set
         if !date_customer_notified.nil?
            msg = "Status #{self.order_status.upcase} to COMPLETED"
            AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)

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
            msg = "Status #{self.order_status.upcase} to COMPLETED"
            AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)

            update(order_status: "completed", date_completed: Time.now)
            return true
         else
            if date_finalization_begun.nil?
               errors.add(:order, "has not been finalized")
               return false
            end

            # check all NON-CANCELED units for archive date, keeping track of 
            # latest. If all have been archived, update the order archive date and flag order as complete
            latest = nil
            units.each do |unit|
               next if unit.unit_status == "canceled"
               if unit.date_archived.nil? 
                  errors.add(:unit, "has not been archived")
                  return false
               else
                  latest = unit.date_archived if latest.nil? 
                  if unit.date_archived  > latest 
                     latest = unit.date_archived
                  end
               end
            end
            msg = "Status #{self.order_status.upcase} to COMPLETED"
            AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)
            update(order_status: "completed", date_completed: Time.now, date_archiving_complete: latest)
            return true
         end
      end
      return false
   end

   def defer_order(user)
      # entering a deferred state or leaving it?
      if self.order_status != 'deferred'
         msg = "Status #{self.order_status.upcase} to DEFERRED"
         AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)

         self.order_status = 'deferred'
         self.date_deferred = Time.now
         self.save!
      else
         # resuming a deferred order
         if self.date_order_approved.nil?
            msg = "Status #{self.order_status.upcase} to REQUESTED"
            AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)

            update(order_status: "requested")
         else
            msg = "Status #{self.order_status.upcase} to APPROVED"
            AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)

            update(order_status: "approved")
         end
      end
   end

   def approve_order(user)
      msg = "Status #{self.order_status.upcase} to APPROVED"
      AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)

      self.order_status = 'approved'
      self.date_order_approved = Time.now
      self.save!

      # purge the transient order items that may exist
      self.order_items.destroy_all
   end

   def decline_fee(user)
      msg = "Status #{self.order_status.upcase} to CANCELED because fee declined"
      AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)
      self.order_status = 'canceled'
      self.date_canceled = Time.now
      self.save!
      invoices.each do |inv|
         if inv.date_fee_paid.blank?
            inv.update(date_fee_declined: Time.now)
         end
      end
   end

   def cancel_order(user)
      msg = "Status #{self.order_status.upcase} to CANCELED"
      AuditEvent.create(auditable: self, event: AuditEvent.events[:status_update], staff_member: user, details: msg)

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
       generate_invoice_pdf(self)
   end

   def self.upaid_customer_report
      file = Tempfile.new( ['unpaid', '.csv'] )
      cids = []
      CSV.open(file, "wb") do |csv|
         csv << ['Name', 'Email', 'Primary Phone', 'Primary Address', 'Billable Phone', 'Billable Address']
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
                  row << pa.short_format.gsub(/\n/, ' ')
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
                  row << ba.short_format.gsub(/\n/, ' ')
               end
            end
            csv << row
         end
      end
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
#  fee                                :decimal(7, 2)
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
#  date_completed                     :datetime
#
