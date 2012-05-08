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
  filter :agency, :as => :select, :input_html => {:class => 'chzn-select', :'data-placeholder' => 'Choose an agency...'}
  filter :order_status, :as => :select, :collection => Order.select(:order_status).uniq.map(&:order_status).sort
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
  filter :academic_status, :as => :select, :input_html => {:class => 'chzn-select'}

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

    f.inputs "Related Information", :class => 'panel three-colum' do 
      f.input :agency
      f.input :customer
    end

    f.inputs "Delivery Information", :class => 'panel columns-none' do 
      f.input :date_finalization_begun, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_archiving_complete, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_patron_deliverables_complete, :as => :string, :input_html => {:class => :datepicker}
      f.input :date_customer_notified, :as => :string, :input_html => {:class => :datepicker}
      f.input :email, :input_html => {:rows => 5}
    end

    f.actions

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
    if order.order_status == 'requested'
      if order.customer.external?
        if order.fee_estimated.nil?

          button_to "Approve Order", approve_order_admin_order_path(order), :disabled => 'true', :method => 'get'
          button_to "Cancel Order", cancel_order_admin_order_path(order), :method => 'get'
        end
      end

    elsif order.order_status == 'canceled'

    elsif order.order_status == 'approved' 
      "No options avaialable.  Order is #{order.order_status}."
      div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :disabled => 'true', :method => 'get' end
      div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_admin_order_path(order.id), :disabled => 'true', :method => 'get' end
      div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_order_path(order.id), :disabled => true end
    end
  end

  #   end
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

  # sidebar :delivery_workflow, :only => :show do
  #   div :class => 'workflow_button' do
  #     button_to "Check Order Ready For Delivery"
  #   end

  #   div :class => 'workflow_button' do
  #     button_to "Deliver Order"
  #   end
  # end

  member_action :approve_order, :method => :put do
    order = Order.find(params[:id])
    order.approve_order
    redirect :back, :notice => "Order #{params[:id]} is now approved."
  end

  member_action :cancel_order, :method => :put do
    order = Order.find(params[:id])
    order.cancel_order
    redirect :back, :notice => "Order #{params[:id]} is now canceled."
  end

  member_action :send_fee_estimate_to_customer, :method => :put do
    order = Order.find(params[:id])
    order.send_fee_estimate_to_customer
    redirect :back, :notice => "A fee estimate email has been sent to #{order.customer.full_name}."
  end

  # member_action :check_order_ready_for_delivery, :method => :put do

  # end



  # member_action :send_order_email, :method => :put do

  # end
end