ActiveAdmin.register Order do
  menu :priority => 3

  actions :all, :except => [:destroy]

  scope :all, :default => true
  scope :awaiting_approval
  scope :approved
  scope :deferred
  scope :in_process
  scope :ready_for_delivery
  scope :complete

 
  filter :id
  filter :agency
  filter :order_status, :as => :select, :collection => Order.select(:order_status).uniq
  filter :order_title
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :customer_last_name, :as => :string, :label => "Customer Last Name"
  filter :date_request_submitted
  filter :date_due
  filter :date_archiving_complete
  filter :date_patron_deliverables_complete
  filter :date_customer_notified
  filter :fee_estimated
  filter :fee_actual
  filter :staff_notes
  filter :academic_status, :as => :select

  index :id => 'orders' do
    selectable_column
    column :id
    column ("Status") {|order| status_tag(order.order_status)}
    column ("Date Request Submitted") {|order| order.date_request_submitted.try(:strftime, "%m/%d/%y")}
    column ("Date Order Approved") {|order| order.date_order_approved.try(:strftime, "%m/%d/%y")}
    column ("Date Archiving Complete") {|order| order.date_archiving_complete.try(:strftime, "%m/%d/%y")}
    column ("Date Patron Deliverables Complete") {|order| order.date_patron_deliverables_complete.try(:strftime, "%m/%d/%y")}
    column ("Date Customer Notified") {|order| order.date_customer_notified.try(:strftime, "%m/%d/%y")}
    column ("Date Due") {|order| order.date_due.try(:strftime, "%m/%d/%y")}
    column ("Units") do |order|
      link_to order.units_count, admin_units_path(:q => {:order_id_eq => order.id})
    end
    column ("Master Files") do |order|
      link_to order.master_files_count, admin_master_files_path(:q => {:order_id_eq => order.id})
    end
    column :agency
    column :customer
    column("") do |order|
      div do
        link_to "Details", resource_path(order), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(order), :class => "member_link edit_link"
      end
    end
  end

  show do
    div :class => 'two-column' do
      panel "Basic Information" do
        attributes_table_for order do
          row :order_status
          row :order_title
          row :special_instructions
          row :staff_notes
        end
      end
    end

    div :class => 'two-column' do
      panel "Approval Information" do
        attributes_table_for order do
          row :date_request_submitted do |customer|
            format_date(customer.date_request_submitted)
          end
          row :date_due do |customer|
            format_date(customer.date_due)
          end
          row :fee_estimated do |customer|
            number_to_currency(customer.fee_estimated)
          end
          row :fee_actual do |customer|
            number_to_currency(customer.fee_actual)
          end
          row :date_deferred do |customer|
            format_date(customer.date_deferred)
          end
          row :date_fee_estimate_sent_to_customer do |customer|
            format_date(customer.date_fee_estimate_sent_to_customer)
          end
          row :date_permissions_given do |customer|
            format_date(customer.date_permissions_given)
          end
        end
      end
    end

    div :class => 'columns-none' do
      panel "Delivery Information" do 
        attributes_table_for order do
          row :date_finalization_begun do |customer|
            format_date(customer.date_finalization_begun)
          end
          row :date_archiving_complete do |customer|
            format_date(customer.date_finalization_begun)
          end
          row :date_patron_deliverables_complete do |customer|
            format_date(customer.date_patron_deliverables_complete)
          end
          row :date_customer_notified do |customer|
            format_date(customer.date_customer_notified)
          end
          row :email do |customer|
            raw(customer.email)
          end
        end
      end
    end
  end

  sidebar "Relaed Information", :only => :show do
    attributes_table_for order do
      row :units do |order|
        link_to "#{order.units.size}", admin_units_path(:q => {:order_id_eq => order.id})
      end
      row :master_files do |order|
        link_to "#{order.master_files.size}", admin_master_files_path(:q => {:order_id_eq => order.id})
      end
      row :bibls do |order|
        link_to "#{order.bibls.size}", admin_bibls_path(:q => {:orders_id_eq => order.id})
      end
      row :customer
      row :agency
    end
  end

  sidebar :approval_workflow, :only => :show do
    div :class => 'workflow_button' do
      if order.approved?
        button_to "Approve Order", approve_order_admin_order_path(order), :disabled => 'true', :method => 'get'
      else
        button_to "Approve Order", approve_order_admin_order_path(order), :method => 'get'
      end
    end
    div :class => 'workflow_button' do 
      if proc {order.order_status == 'requested' or order.order_status == 'deferred'}
        button_to "Cancel Order", cancel_order_admin_order_path(order), :method => 'get'
      else
        button_to "Cancel Order", cancel_order_admin_order_path(order), :disabled => 'true', :method => 'get'
      end
    end
    div :class => 'workflow_button' do
      button_to "Send Fee Estimate" if order.fee_estimated? and not order.fee_actual?
    end
  end

  sidebar :delivery_workflow, :only => :show do
    div :class => 'workflow_button' do
      button_to "Check Order Ready For Delivery"
    end

    div :class => 'workflow_button' do
      button_to "Deliver Order"
    end
  end

  member_action :approve_order
  member_action :cancel_order
  member_action :check_order_ready_for_delivery
  member_action :send_fee_estimate_to_customer
  member_action :send_order_email

  controller do
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

    def approve_order
      message = ActiveSupport::JSON.encode( {:order_id => params[:id]})
      publish :update_order_status_approved, message
      flash[:notice] = "Order #{params[:id]} is now approved."
      redirect_to admin_order_path
    end

    def cancel_order
      message = ActiveSupport::JSON.encode( {:order_id => params[:id]} )
      publish :update_order_status_canceled, message
      flash[:notice] = "The order is now canceled."
      redirect_to admin_order_path
    end

    def check_order_ready_for_delivery
      message = ActiveSupport::JSON.encode( {:order_id => params[:id]})
      publish :check_order_ready_for_delivery, message
      flash[:notice] = "Workflow started at checking the completeness of the order."
      redirect_to admin_order_path
    end

    def send_fee_estimate_to_customer
      if RAILS_ENV == 'test' or RAILS_ENV == 'development'
        computing_id = 'localhost'
      else
        computing_id = request.env['HTTP_REMOTE_USER'].to_s
      end
      @user = StaffMember.find_by_computing_id(computing_id) 
      @first_name = @user.first_name
      message = ActiveSupport::JSON.encode( {:order_id => params[:order_id], :first_name => @first_name})
      publish :send_fee_estimate_to_customer, message
      flash[:notice] = "Fee estimate sent to customer."
      redirect_to :action => "show", :id => params[:order_id]
    end

    def send_order_email
      message = ActiveSupport::JSON.encode( {:order_id => params[:id]})
      publish :update_order_email_date, message
      flash[:notice] = "Email sent to patron."
      redirect_to :action => "show", :id => params[:order_id]
    end
  end
end