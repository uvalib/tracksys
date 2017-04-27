ActiveAdmin.register Order do
   menu :priority => 4
   config.batch_actions = false

   before_update do |order|
      prior = Order.find(order.id)
      if prior.order_status != order.order_status
         Rails.logger.info "Order #{order.id} status changed from #{prior.order_status} to #{order.order_status} by #{current_user.computing_id}"
         msg = "Status #{prior.order_status.upcase} to #{order.order_status.upcase}"
         AuditEvent.create(auditable: order, event: AuditEvent.events[:status_update],
         staff_member: current_user, details: msg)
      end
   end

   # strong paramters handling
   permit_params :order_status, :order_title, :special_instructions, :staff_notes, :date_request_submitted, :date_due,
   :fee_estimated, :fee_actual, :date_deferred, :date_fee_estimate_sent_to_customer, :date_permissions_given,
   :agency_id, :customer_id, :date_finalization_begun, :date_archiving_complete, :date_patron_deliverables_complete,
   :date_customer_notified, :email

   collection_action :autocomplete, method: :get do
      suggestions = []
      like_keyword = "#{params[:query]}%"
      Order.where("id like ?", like_keyword).each do |o|
         suggestions << "#{o.id}"
      end
      resp = {query: "Unit", suggestions: suggestions}
      render json: resp, status: :ok
   end

   csv do
      column :id
      column :order_status
      column :order_title
      column :special_instructions
      column("Date Archived") {|order| format_date(order.date_archiving_complete)}
      column("Deliverables Complete") {|order| format_date(order.date_patron_deliverables_complete)}
      column("Customer Notified") {|order| format_date(order.date_customer_notified)}
      column("Date Due") {|order| format_date(order.date_due)}
      column :units_count
      column :master_files_count
      column("Customer") {|order| order.customer.full_name }
      column("Department") {|order| order.customer.department.name if !order.customer.department.blank?}
      column("Acedemic Status") {|order| order.customer.academic_status.name}
      column("Charged Fee") {|order| order.fee_actual}
   end

   config.clear_action_items!
   action_item :unpaid, :only => :index do
      if current_user.admin? || current_user.supervisor?
         raw("<a href='/admin/orders/overdue' target='_blank'>Unpaid Customers</a>")
      end
   end
   action_item :new, :only => :index do
      raw("<a href='/admin/orders/new'>New</a>") if !current_user.viewer? && !current_user.student?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student?
   end

   scope :all, :default => true
   scope :awaiting_approval
   scope :approved
   scope :deferred
   scope :in_process
   scope :ready_for_delivery
   scope :complete
   scope :due_today
   scope :due_in_a_week
   scope :overdue
   scope :unpaid
   scope :uniq

   filter :id_equals, :label=>"ID"
   filter :order_title_contains, :label=>"Title"
   filter :customer_last_name_starts_with, :label => "Customer Last Name"
   filter :date_request_submitted
   filter :date_due
   filter :order_status, :as => :select, :collection => Order::ORDER_STATUSES
   filter :date_archiving_complete
   filter :date_patron_deliverables_complete
   filter :date_customer_notified
   filter :staff_notes_contains, :label=>"Staff Notes"
   filter :special_instructions_contains, :label=>"Special Instructions"
   filter :department, :as => :select
   filter :agency, :as => :select

   index :id => 'orders' do
      selectable_column
      column :id, :class => 'sortable_short'
      column ("Status") do |order|
         status_tag(order.order_status)
      end
      column :title do |order|
         order.title.truncate(80) unless order.title.nil?
      end
      column ("Special Instructions") do |order|
         order.special_instructions.to_s.truncate(50)
      end
      column ("Request Submitted"), :sortable => :date_request_submitted do |order|
         order.date_request_submitted.try(:strftime, "%m/%d/%y")
      end
      column ("Archiving Complete"), :sortable => :date_archiving_complete do |order|
         order.date_archiving_complete.try(:strftime, "%m/%d/%y")
      end
      column ("Deliverables Complete"), :sortable => :date_patron_deliverables_complete do |order|
         order.date_patron_deliverables_complete.try(:strftime, "%m/%d/%y")
      end
      column ("Customer Notified"), :sortable => :date_customer_notified do |order|
         order.date_customer_notified.try(:strftime, "%m/%d/%y")
      end
      column ("Date Due") do |order|
         order.date_due.try(:strftime, "%m/%d/%y")
      end
      column ("Units"), :sortable => :units_count, :class => 'sortable_short' do |order|
         link_to order.units_count, admin_units_path(:q => {:order_id_eq => order.id})
      end
      column ("Master Files"), :sortable => :master_files_count do |order|
         link_to order.master_files_count, admin_master_files_path(:q => {:order_id_eq => order.id})
      end
      column :agency, :sortable => 'agencies.name', :class => 'sortable_short'
      column :customer, :sortable => :"customers.last_name", :class => 'sortable_short'
      column ("Charged Fee") do |customer|
         number_to_currency(customer.fee_actual)
      end
      column("") do |order|
         div do
            link_to "Details", resource_path(order), :class => "member_link view_link"
         end
         if !current_user.viewer? && !current_user.student?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(order), :class => "member_link edit_link"
            end
         end
      end
   end

   show :title => proc{|order| "Order ##{order.id}"} do
      err = order.last_error
      if !err.blank?
         div :class => "columns-none error" do
            raw("RECENT ERROR: <a href='/admin/job_statuses/#{err[:job]}'>#{err[:error]}</a>")
         end
      end
      render "details", :context => self
   end

   form do |f|
      f.inputs "Basic Information", :class => 'panel three-column' do
         f.input :order_status, :as => :select, :collection => Order::ORDER_STATUSES
         f.input :order_title
         f.input :special_instructions, :input_html => {:rows => 3}
         f.input :staff_notes, :input_html => {:rows => 3}
      end

      f.inputs "Approval Information", :class => 'panel three-column' do
         f.input :date_request_submitted, :as => :string, :input_html => {:class => :datepicker}
         f.input :date_due, :as => :string, :input_html => {:class => :datepicker}
         f.input :fee_estimated, :as => :string
         f.input :fee_actual, :as => :string
         f.input :date_deferred, :as => :string, :input_html => {:class => :datepicker}
         f.input :date_fee_estimate_sent_to_customer, :as => :string, :input_html => {:class => :datepicker}
         f.input :date_permissions_given, :as => :string, :input_html => {:class => :datepicker}
      end

      f.inputs "Related Information", :class => 'panel three-column' do
         f.input :agency_id, :as => :select,  :input_html => {:class => 'chosen-select',  :style => 'width: 210px'}, :collection => Agency.order(:names_depth_cache).map {|a| ["    |---- " * a.depth + a.name,a.id]}.insert(0, ""), :include_blank => true
         f.input :customer, :as => :select, :input_html => {:class => 'chosen-select',  :style => 'width: 210px'}
      end

      f.inputs "Delivery Information", :class => 'panel columns-none' do
         f.input :date_finalization_begun, :as => :string, :input_html => {:class => :datepicker}
         f.input :date_archiving_complete, :as => :string, :input_html => {:class => :datepicker}
         f.input :date_patron_deliverables_complete, :as => :string, :input_html => {:class => :datepicker}
         f.input :date_customer_notified, :as => :string, :input_html => {:class => :datepicker}
         f.input :email, :as => :text
      end

      f.inputs :class => 'columns-none' do
         f.actions
      end
   end

   sidebar :approval_workflow, :only => :show,  if: proc{ !current_user.viewer? && !current_user.student? } do
      render "approval_workflow", :context=>self
   end

   sidebar "Delivery Workflow", :only => :show,  if: proc{ !current_user.viewer? && !current_user.student? }  do
      render "delivery_workflow", :context=>self
   end

   sidebar "Related Information", :only => :show do
      render "related_info", :context=>self
   end

   collection_action :overdue, :method=>:get do
      report = Order.upaid_customer_report
      send_file(report.path)
   end

   member_action :approve_order, :method => :put do
      begin
         order = Order.find(params[:id])
         order.update_attributes!(:order_status => "approved")
         redirect_to "/admin/orders/#{params[:id]}", :notice => "Order #{params[:id]} is now approved."
      rescue ActiveRecord::RecordInvalid => invalid
         redirect_to "/admin/orders/#{params[:id]}", :alert => "#{invalid.record.errors.full_messages.join(', ')}"
      end
   end

   member_action :cancel_order, :method => :put do
      order = Order.find(params[:id])
      order.cancel_order
      redirect_to "/admin/orders/#{params[:id]}", :notice => "Order #{params[:id]} is now canceled."
   end

   member_action :send_fee_estimate_to_customer, :method => :put do
      order = Order.find(params[:id])
      order.send_fee_estimate_to_customer()
      redirect_to "/admin/orders/#{params[:id]}", :notice => "A fee estimate email has been sent to #{order.customer.full_name}."
   end

   member_action :check_order_ready_for_delivery, :method => :put do
      order = Order.find(params[:id])
      order.check_order_ready_for_delivery
      redirect_to "/admin/orders/#{params[:id]}", :notice => "Order #{order.id} is being checked to see if it is ready."
   end

   member_action :recreate_email, :method => :put do
      order = Order.find(params[:id])
      CreateOrderEmail.exec_now({order: order})
      redirect_to "/admin/orders/#{params[:id]}", :notice => "New email generated, but not sent."
   end

   member_action :send_order_email, :method => :put do
      order = Order.find(params[:id])
      order.send_order_email
      redirect_to "/admin/orders/#{params[:id]}", :notice => "Email sent to #{order.customer.full_name}."
   end

   member_action :generate_pdf_notice, :method => :put do
      order = Order.find(params[:id])
      pdf = order.generate_notice
      send_data(pdf.render, :filename => "#{order.id}.pdf", :type => "application/pdf", :disposition => 'inline')
   end

   controller do
      before_filter :get_audit_log, only: [:show]
      def get_audit_log
         @audit_log = AuditEvent.where(auditable: resource)
         puts "LOG #{@audit_log.to_json} =================================================="
      end
   end
end
