ActiveAdmin.register Order do
   menu :priority => 4

   actions :all, :except => [:destroy]
   config.clear_action_items!
   config.per_page = [30, 50, 100, 250]

   # strong paramters handling
   permit_params :order_status, :order_title, :special_instructions, :staff_notes, :date_request_submitted, :date_due,
      :fee, :date_deferred, :date_fee_estimate_sent_to_customer,
      :agency_id, :customer_id, :date_finalization_begun, :date_archiving_complete, :date_patron_deliverables_complete,
      :date_customer_notified, :email

   # eager load to preven n+1 queries, and improve performance
   includes :department, :agency, :customer, :academic_status

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
      column("Charged Fee") {|order| order.fee}
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

   scope :active, :default => true
   scope :all, :show_count => true
   scope :awaiting_approval
   scope :in_process
   scope :deferred
   scope :ready_for_delivery
   scope :complete
   scope :canceled
   scope :due_today
   scope :due_in_a_week
   scope :overdue
   scope :unpaid

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

   # INDEX ====================================================================
   #
   index :id => 'orders' do
      selectable_column
      column :id, :class => 'sortable_short' do |order|
         link_to order.id, resource_path(order), :class => "member_link view_link"
      end
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
      column ("Fee") do |customer|
         number_to_currency(customer.fee)
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

   # DETAILS Page =============================================================
   #
   show :title => proc{|order| "Order ##{order.id}"} do
      err = order.last_error
      if !err.blank?
         div :class => "columns-none error" do
            raw("RECENT ERROR: <a href='/admin/job_statuses/#{err[:job]}'>#{err[:error]}</a>")
         end
      end
      render "details", :context => self
   end

   # EDIT page =================================================================
   #
   form :partial => "form"

   # Only show order workflow for active orders (not canceled or complete)
   sidebar :order_workflow, :only => :show,  if: proc{
      !current_user.viewer? && !current_user.student? &&
      resource.order_status != "completed" && resource.order_status != "canceled"  } do
      render "approval_workflow", :context=>self
   end

   sidebar "Delivery Workflow", :only => :show,  if: proc{
      resource.order_status != "canceled" &&
      resource.has_patron_deliverables? && !current_user.viewer? &&
      !current_user.student? && resource.order_status != "canceled" }  do
      render "delivery_workflow", :context=>self
   end

   sidebar "Related Information", :only => :show do
      render "related_info", :context=>self
   end

   collection_action :overdue, :method=>:get do
      report = Order.upaid_customer_report
      send_file(report.path,{filename: "unpaid_customers.csv"})
   end

   # BATCH ACTIONS ============================================================
   #
   batch_action :approve_orders do |selection|
      failed = []
      Order.find(selection).each do |s|
         begin
            s.approve_order(current_user)
         rescue Exception=>e
            failed << s.id
         end
      end
      if failed
         flash[:notice] = "Unable to approve order(s) #{failed.join(',')}. See order details for reason."
      end
      redirect_to "/admin/orders"
   end

   batch_action :cancel_orders do |selection|
      failed = []
      Order.find(selection).each do |s|
         begin
            s.cancel_order(current_user)
         rescue Exception=>e
            failed << s.id
         end
      end
      if !failed.empty?
         flash[:notice] = "Unable to cancel order(s) #{failed.join(',')}. See order details for reason."
      end
      redirect_to "/admin/orders"
   end

   batch_action :complete_orders do |selection|
      failed = []
      Order.find(selection).each {|s| failed << s.id if !s.complete_order(current_user) }
      if !failed.empty?
         flash[:notice] = "Unable to complete order(s) #{failed.join(',')}. See order details for reason."
      end
      redirect_to "/admin/orders"
   end

   # MEMBER ACTIONS ===========================================================
   #
   member_action :approve_order, :method => :put do
      order = Order.find(params[:id])
      order.approve_order(current_user)
      redirect_to "/admin/orders/#{params[:id]}", :notice => "Order #{params[:id]} is now approved."
   end

   member_action :defer_order, :method => :put do
      order = Order.find(params[:id])
      was_deferred = order.order_status == 'deferred'
      order.defer_order(current_user)
      msg = "Order #{params[:id]} is now deferred."
      if was_deferred
         msg = "Order #{params[:id]} has been reactivated."
      end
      redirect_to "/admin/orders/#{params[:id]}", :notice => msg
   end

   member_action :cancel_order, :method => :put do
      order = Order.find(params[:id])
      order.cancel_order(current_user)
      redirect_to "/admin/orders/#{params[:id]}", :notice => "Order #{params[:id]} is now canceled."
   end

   member_action :complete_order, :method => :put do
      order = Order.find(params[:id])
      if order.complete_order(current_user)
         redirect_to "/admin/orders/#{params[:id]}"
      else
         redirect_to "/admin/orders/#{params[:id]}", :flash => {:error => "Order #{params[:id]} is not complete: #{order.errors.full_messages.to_sentence}"}
      end
   end

   member_action :send_fee_estimate_to_customer, :method => :put do
      o = Order.find(params[:id])
      msg = "Status #{o.order_status.upcase} to AWAIT_FEE"
      AuditEvent.create(auditable: o, event: AuditEvent.events[:status_update], staff_member: current_user, details: msg)

      SendFeeEstimateToCustomer.exec_now( {:order_id => params[:id]} )
      redirect_to "/admin/orders/#{params[:id]}", :notice => "A fee estimate email has been sent to customer."
   end

   member_action :check_order_ready_for_delivery, :method => :put do
      CheckOrderReadyForDelivery.exec( {:order_id => params[:id]})
      redirect_to "/admin/orders/#{params[:id]}", :notice => "Order #{params[:id]} is being checked to see if it is ready."
   end

   member_action :recreate_email, :method => :put do
      order = Order.find(params[:id])
      CreateOrderEmail.exec_now({order: order})
      redirect_to "/admin/orders/#{params[:id]}", :notice => "New email generated, but not sent."
   end

   member_action :send_order_email, :method => :put do
      SendOrderEmail.exec_now({:order_id => params[:id], user: current_user})
      redirect_to "/admin/orders/#{params[:id]}", :notice => "Email sent to customer."
   end

   member_action :send_order_alt_email, :method => :put do
      order = Order.find(params[:id])
      msg = OrderMailer.web_delivery(order, ['holding'])
      msg.body = order.email.to_s
      msg.to = [params[:email]]
      msg.date = Time.now
      msg.deliver

      sn = order.staff_notes
      sn << "" if sn.nil?
      sn << " " if !sn.blank?
      sn << "Order notification sent to alternate email address: #{params[:email]}."
      order.update(staff_notes: sn)

      redirect_to "/admin/orders/#{params[:id]}", :notice => "Email sent to #{params[:email]}"
   end

   member_action :generate_pdf_notice, :method => :put do
      order = Order.find(params[:id])
      pdf = order.generate_notice
      send_data(pdf.render, :filename => "#{order.id}.pdf", :type => "application/pdf", :disposition => 'inline')
   end

   member_action :reset_dates, :method => :post do
      o = Order.find(params[:id])
      AuditEvent.create(auditable: o, event: AuditEvent.events[:status_update],
         staff_member: current_user, details: "Finalize, archive and deliverable dates reset")
      o.update(date_finalization_begun: nil, date_archiving_complete: nil,
         date_patron_deliverables_complete: nil)
      render plain: "OK"
   end

   controller do
      before_action :get_audit_log, only: [:show]
      def get_audit_log
         @audit_log = AuditEvent.where(auditable: resource)
      end
   end
end
