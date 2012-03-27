ActiveAdmin.register Order, :namespace => :patron do
  menu :priority => 3

  actions :all, :except => [:destroy]

  scope :all
  scope :awaiting_approval, :defaults => true
  scope :deferred
  scope :in_process

  filter :id

  index do
    selectable_column
    column :id
    column (:order_status) {|order| order.order_status.capitalize}
    column (:date_request_submitted) {|order| format_date(order.date_request_submitted)}
    column (:date_due) {|order| format_date(order.date_due)}
    default_actions
  end

  show do
    div :class => 'three-column' do
      panel "Order Information" do
        attributes_table_for order do
          row (:order_status) {|order| order.order_status.capitalize}
          row (:date_request_submitted) {|order| format_date(order.date_request_submitted)}
          row (:fee_estimated) {|order| number_to_currency(order.fee_estimated, :precision => 0)}
          row (:fee_actual) {|order| number_to_currency(order.fee_actual, :precision => 0)}
          row (:special_instructions) {|order| simple_format(order.special_instructions)}
          row (:staff_notes) {|order| simple_format(order.staff_notes)}
        end
      end
    end

    div :class => 'three-column' do
      panel "Customer Information" do
        attributes_table_for order.customer do
          row ("Name") {|customer| link_to "#{customer.full_name}", patron_customer_path(customer)}
          row :email
          row :academic_status
          row :orders_count
        end
      end
    end

    div :class => 'three-column' do
      panel "Agency Information" do
        attributes_table_for order.agency do
          row :name
          row ("Parent Agencies") {|agency| agency.names_depth_cache}
        end
      end
    end

    div :class => 'columns-none' do
      panel "Units" do
        table_for (order.units) do
          column("ID") {|unit| link_to "#{unit.id}", patron_unit_path(unit) }
          column :unit_status
          column :bibl_title
          column :bibl_call_number
        end
      end
    end

    div :class => 'columns-none' do
      panel "Automation Messages" do
        table_for order.automation_messages do
          column("ID") {|am| link_to "#{am.id}", patron_automation_message_path(am)}
          column (:message_type) {|am| am.message_type.capitalize}
          column (:active_error) {|am| format_boolean_as_yes_no(am.active_error)}
          column (:workflow_type) {|am| am.workflow_type.capitalize}
          column (:message) {|am| truncate_words(am.message)}
          column (:created_at) {|am| format_datetime(am.created_at)}
        end
      end
    end
  end

  form do |f|
    f.inputs "Details" do
      f.input :fee_estimated, {:step => '25'}
      f.input :fee_actual, {:step => '25'}
      f.input :staff_notes
    end
    f.buttons
  end

  # sidebar :approval_workflow, :only => [:show] do
  #   div :class => 'workflow_button' do
  #     if order.approved?
  #       button_to "Approve Order", approve_order_admin_order_path(order), :disabled => 'true', :method => 'get'
  #     else
  #       button_to "Approve Order", approve_order_admin_order_path(order), :method => 'get'
  #     end
  #   end
  #   div :class => 'workflow_button' do 
  #     if proc {order.order_status == 'requested' or order.order_status == 'deferred'}
  #       button_to "Cancel Order", cancel_order_admin_order_path(order), :method => 'get'
  #     else
  #       button_to "Cancel Order", cancel_order_admin_order_path(order), :disabled => 'true', :method => 'get'
  #     end
  #   end
  #   div :class => 'workflow_button' do
  #     button_to "Send Fee Estimate" if order.fee_estimated? and not order.fee_actual?
  #   end
  # end

  action_item :only => :show do
    if not order.approved?
      link_to "Approve", approve_order_patron_order_path(order)
    end
  end

  action_item :only => :show do
    link_to "Cancel", cancel_order_patron_order_path(order) unless order.canceled?
  end

  action_item :only => :show do
    link_to "Send Fee Estaimte"
  end

  member_action :approve_order
  member_action :cancel_order

  controller do
    require 'activemessaging/processor'
    include ActiveMessaging::MessageSender

    def approve_order
      message = ActiveSupport::JSON.encode( {:order_id => params[:id]})
      publish :update_order_status_approved, message
      flash[:notice] = "Order #{params[:id]} is now approved."
      redirect_to patron_order_path
    end

    def cancel_order
      message = ActiveSupport::JSON.encode( {:order_id => params[:id]} )
      publish :update_order_status_canceled, message
      flash[:notice] = "The order is now canceled."
      redirect_to patron_order_path
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
      redirect_to patron_order_path
    end
  end
end