class Order < ActiveRecord::Base

   ORDER_STATUSES = ['requested', 'deferred', 'canceled', 'approved', 'completed']
   include BuildOrderPDF

   def as_json(options)
      super(:except => [:email])
   end

   #------------------------------------------------------------------
   # relationships
   #------------------------------------------------------------------
   belongs_to :agency, :counter_cache => true
   belongs_to :customer, :counter_cache => true, :inverse_of => :orders

   has_many :job_statuses, :as => :originator, :dependent => :destroy

   has_many :sirsi_metadata, ->{ where(type: "SirsiMetadata").uniq }, :through => :units, :source=>:metadata
   has_many :xml_metadata, ->{where(type: "XmlMetadata").uniq}, :through => :units, :source=>:metadata
   has_many :invoices, :dependent => :destroy
   has_many :master_files, :through => :units
   has_many :units, :inverse_of => :order

   has_one :academic_status, :through => :customer
   has_one :department, :through => :customer
   has_one :primary_address, :through => :customer
   has_one :billable_address, :through => :customer

   #------------------------------------------------------------------
   # scopes
   #------------------------------------------------------------------
   scope :complete, ->{ where("date_archiving_complete is not null") }
   scope :deferred, ->{where("order_status = 'deferred'") }
   scope :in_process, ->{where("date_archiving_complete is null").where("order_status = 'approved'") }
   scope :awaiting_approval, ->{where("order_status = 'requested'") }
   scope :approved,->{ where("order_status = 'approved'") }
   scope :ready_for_delivery, ->{ where("`orders`.email is not null").where(:date_customer_notified => nil) }
   scope :recent,
   lambda {|limit=5|
      order('date_request_submitted DESC').limit(limit)
   }
   scope :unpaid, ->{ where("fee_actual > 0").joins(:invoices).where('`invoices`.date_fee_paid IS NULL').where('`invoices`.permanent_nonpayment IS false').where('`orders`.date_customer_notified > ?', 2.year.ago).order('fee_actual desc') }
   scope :from_fine_arts, ->{ joins(:agency).where("agencies.name" => "Fine Arts Library") }
   scope :not_from_fine_arts, ->{ where('agency_id != 37 or agency_id is null') }
   scope :complete, ->{ where("date_archiving_complete is not null OR order_status = 'completed'") }

   #------------------------------------------------------------------
   # validations
   #------------------------------------------------------------------
   validates :date_due, :date_request_submitted, :presence => {
      :message => 'is required.'
   }
   validates_presence_of :customer

   validates :order_title, :uniqueness => true, :allow_blank => true

   validates :fee_estimated, :fee_actual, :numericality => {:greater_than_or_equal_to => 0, :allow_nil => true}

   validates :order_status, :inclusion => { :in => ORDER_STATUSES,
      :message => 'must be one of these values: ' + ORDER_STATUSES.join(", ")}

   validates_datetime :date_request_submitted

   validates_date :date_due, :on => :update
   validates_date :date_due, :on => :create, :on_or_after => 28.days.from_now, :if => 'self.order_status == "requested"'

   validates_datetime :date_order_approved,
      :date_deferred,
      :date_canceled,
      :date_permissions_given,
      :date_started,
      :date_archiving_complete,
      :date_patron_deliverables_complete,
      :date_customer_notified,
      :date_finalization_begun,
      :date_fee_estimate_sent_to_customer,
      :allow_blank => true

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
   end

   before_destroy do
      if self.units.any? || self.invoices.any?
         errors[:base] << "cannot delete order that is associated with invoices or units"
      end
      return true
   end

   #------------------------------------------------------------------
   # serializations
   #------------------------------------------------------------------
   # Email sent to customers should be save to DB as a TMail object.  During order delivery approval phase, the email
   # must be revisited when staff decide to send it.
   #serialize :email, TMail::Mail

   #------------------------------------------------------------------
   # public instance methods
   #------------------------------------------------------------------
   # Returns a boolean value indicating whether the Order is active, which is
   # true unless the Order has been canceled or deferred.
   def active?
      if order_status == 'canceled' or order_status == 'deferred'
         return false
      else
         return true
      end
   end

   # Returns a boolean value indicating whether the Order is approved
   # for digitization ("order") or not ("request").
   def approved?
      if order_status == 'approved'
         return true
      else
         return false
      end
   end

   def canceled?
      if order_status == 'canceled'
         return true
      else
         return false
      end
   end

   # Returns a boolean value indicating whether this Order has
   # associated Invoice records.
   def invoices?
      return invoices.any?
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
      if Time.now.to_date == timespan.to_date
         where("date_due = ?", Date.today)
      elsif Time.now > timespan
         where("date_due < ?", Date.today).where("date_due > ?", timespan)
      else
         where("date_due > ?", Date.today).where("date_due < ?", timespan)
      end
   end
   def self.overdue
      date=0.days.ago
      where("date_request_submitted > ?", date - 1.years ).where("date_due < ?", date).where("date_deferred is NULL").where("date_canceled is NULL").where("order_status != 'canceled'").where("date_patron_deliverables_complete is NULL").where("order_status != 'deferred'").where("order_status != 'completed'")
   end


   # Determine if any of an Order's Units are not 'approved' or 'cancelled'
   def ready_to_approve?
      status = self.units.map(&:unit_status) & ['condition', 'copyright', 'unapproved']
      return status.empty?
   end

   def title
      return self.order_title if !self.order_title.blank?
      return self.sirsi_metadata.first.title if !self.sirsi_metadata.blank?
      return self.xml_metadata.first.title if !self.xml_metadata.blank?
      return nil
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
         if u.intended_use.description != "Digital Collection Building"
            return true if u.include_in_dl == false   # this has a patron deliverable
            return true if u.include_in_dl == true &&  u.metadata.availability_policy_id? # DL and Patron deliverables
         end
      end
      return false
   end

   def check_order_ready_for_delivery
      CheckOrderReadyForDelivery.exec( {:order => self})
   end

   def send_fee_estimate_to_customer()
      SendFeeEstimateToCustomer.exec( {:order => self})
   end

   def send_order_email
      SendOrderEmail.exec({:order => self})
   end

   def generate_notice
       generate_invoice_pdf(self, self.fee_actual)
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
#  date_permissions_given             :datetime
#  date_started                       :datetime
#  date_due                           :date
#  date_customer_notified             :datetime
#  fee_estimated                      :decimal(7, 2)
#  fee_actual                         :decimal(7, 2)
#  entered_by                         :string(255)
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
