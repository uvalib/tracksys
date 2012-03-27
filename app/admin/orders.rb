ActiveAdmin.register Order do
  menu :priority => 3

  actions :all, :except => [:destroy]

  scope :all, :default => true
  scope :awaiting_approval
  scope :deferred
  scope :in_process
  scope :complete

  filter :agency
  filter :customer
  filter :date_request_submitted
  filter :date_due
  filter :date_archiving_complete
  filter :date_patron_deliverables_complete
  filter :date_customer_notified
  filter :fee_estimated
  filter :fee_actual
  filter :staff_notes

  index :id => 'orders' do
    column :id
    column ("Status") {|order| status_tag(order.order_status)}
    column ("Date Request Submitted") {|order| order.date_request_submitted.try(:strftime, "%m/%d/%y")}
    column ("Date Order Approved") {|order| order.date_order_approved.try(:strftime, "%m/%d/%y")}
    column ("Date Archiving Complete") {|order| order.date_archiving_complete.try(:strftime, "%m/%d/%y")}
    column ("Date Patron Deliverables Complete") {|order| order.date_patron_deliverables_complete.try(:strftime, "%m/%d/%y")}
    column ("Date Customer Notified") {|order| order.date_customer_notified.try(:strftime, "%m/%d/%y")}
    column ("Date Due") {|order| order.date_due.try(:strftime, "%m/%d/%y")}
    column ("Units") do |order|
      link_to order.units_count, "units?q%5Border_id_eq%5D=#{order.id}"
    end
    column ("Master Files") do |order|
      link_to order.master_files_count, "master_files?q%5Bcorder_id_eq%5D=#{order.id}&order=filename_asc"
    end
    column :agency
    column :customer
    default_actions
  end

  show do
    div :class => 'two-column' do

    end
    div :class => 'two-column' do 
      panel "Customer Details", :id => 'customers', :toggle => 'show' do
        attributes_table_for order.customer do
          row("Name") {link_to "#{order.customer_full_name}", admin_customer_path(order.customer)}
          row :email
        end
      end
    end

    div :class => 'two-column' do
      panel "Agency Details", :id => 'agencies', :toggle => 'show' do
        attributes_table_for order.agency do 
          row("Name") {auto_link order.agency_name}
        end
      end
    end

    div :class => 'columns-none' do
      panel "Units (#{order.units_count})", :id => 'units', :toggle => 'hide' do
        table_for (order.units) do
          column("ID") {|unit| link_to "#{unit.id}", admin_unit_path(unit) }
          column :unit_status
          column :bibl_title
          column :bibl_call_number
          column :date_archived
          column :date_dl_deliverables_ready
          column("# of Master Files") {|unit| unit.master_files_count.to_s}
        end
      end

      panel "Automation Messages (#{order.automation_messages_count})", :id => 'automation_messages', :toggle => 'hide' do
        table_for order.automation_messages do
          column("ID") {|am| link_to "#{am.id}", admin_automation_message_path(am)}
          column :message_type
          column :active_error
          column :workflow_type
          column(:message) {|am| truncate_words(am.message)}
          column(:created_at) {|am| format_date(am.created_at)}
          column("Sent By") {|am| "#{am.app.capitalize}, #{am.processor}"}
        end
      end
    end
  end

  # form do |f|
  #   f.inputs "Details" do
  #     f.input :fee_estimated
  #     f.input :fee_actual
  #     f.input :staff_notes
  #   end
  #   f.buttons
  # end

  sidebar :approval_workflow, :only => [:show] do
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

  sidebar :delivery_workflow, :only => [:show] do
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