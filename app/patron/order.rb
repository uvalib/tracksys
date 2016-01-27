ActiveAdmin.register Order, :namespace => :patron do
  menu :priority => 3

  actions :all, :except => [:destroy]

  scope :all, :default => true
  scope :awaiting_approval
  scope :deferred
  scope :in_process

  filter :id
  filter :agency, :as => :select, :input_html => {:class => 'chzn-select', :'data-placeholder' => 'Choose an agency...'}
  filter :order_status, :as => :select, :collection => Order::ORDER_STATUSES
  filter :order_title
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :customer_last_name, :as => :string, :label => "Customer Last Name"
  filter :bibls_id, :as => :numeric
  filter :date_request_submitted
  filter :date_due
  filter :fee_estimated
  filter :fee_actual
  filter :staff_notes
  filter :academic_status, :as => :select, :input_html => {:class => 'chzn-select'}

  batch_action :set_to_fine_arts do |selection|
    Order.find(selection).each do |order|
      order.update_attribute(:agency_id, 37)
    end
    redirect_to :back, :alert => "Set agency to Fine Arts Library on #{selection.length} orders."
  end

  index do
    selectable_column
    column :id
    column ("Status") {|order| status_tag(order.order_status)}
    column :order_title
    column (:date_request_submitted) {|order| format_date(order.date_request_submitted)}
    column (:date_due) {|order| format_date(order.date_due)}
    column ("Units") do |order|
      link_to order.units_count, patron_units_path(:q => {:order_id_eq => order.id})
    end
    column :customer
    column :agency
    column("") do |order|
      div do
        link_to "Details", resource_path(order), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(order), :class => "member_link edit_link"
      end
    end
  end

  show :title => proc{|order| "Order ##{order.id}"} do
    div :class => 'two-column' do
      panel "Basic Information" do
        attributes_table_for order do
          row ("Status") do |order|
            status_tag(order.order_status)
          end
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
  end

  form do |f|
    f.inputs "Basic Information", :class => 'panel three-column' do
      f.input :order_status, :as => :select, :collection => Order::ORDER_STATUSES, :input_html => {:class => 'chzn-select', :style => 'width: 150px'}
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
      f.input :agency, :as => :select, :include_blank => true, :input_html => {:class => 'chzn-select-deselect'}
      f.input :customer, :as => :select, :input_html => {:class => 'chzn-select'}
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end
  end

   sidebar :approval_workflow, :only => :show do
    if order.order_status == 'requested'
      if order.customer.external?
        if order.fee_estimated.nil?
          # External customers (who require a fee estaimte) for which there IS NO estimated fee
          div :class => 'workflow_button' do button_to "Approve Order", approve_order_patron_order_path(order.id), :disabled => 'true', :method => :put end
          div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_patron_order_path(order.id), :method => :put end
          div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_patron_order_path(order.id), :disabled => true, :method => :put end
          div do "Either enter an estimated fee must or cancel this order." end
        elsif order.fee_estimated
          if order.fee_actual.nil?
            # External customers (who require a fee estaimte) for which there IS estimated fee but actual fee is blank.
            # Actions available: Cancel or Send Fee Estimate
            div :class => 'workflow_button' do button_to "Approve Order", approve_order_patron_order_path(order.id), :disabled => 'true', :method => :put end
            div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_patron_order_path(order.id), :method => :put end
            div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_patron_order_path(order.id), :method => :put end
            div do "Either send fee estimate or cancel this order." end
          else
            # External customers (who require a fee) for which there IS both an estimated fee and actual fee
            # Actions available: Approve or Cancel
            if order.has_units_being_prepared.any?
              div :class => 'workflow_button' do button_to "Approve Order", approve_order_patron_order_path(order.id), :disabled => 'true', :method => :put end
              div do "You must approve or cancel this order's units before approving." end
            else
              div :class => 'workflow_button' do button_to "Approve Order", approve_order_patron_order_path(order.id), :method => :put end
            end
            div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_patron_order_path(order.id), :method => :put end
            div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_patron_order_path(order.id), :disabled => 'true', :method => :put end
            div do "Either approve or cancel this order." end
          end
        end
      elsif not order.customer.external?
        # Internal customers require no fee.
        if order.has_units_being_prepared.any?
          div :class => 'workflow_button' do button_to "Approve Order", approve_order_patron_order_path(order.id), :disabled => 'true', :method => :put end
          div do "You must approve or cancel this order's units before approving." end
        else
          div :class => 'workflow_button' do button_to "Approve Order", approve_order_patron_order_path(order.id), :method => :put end
        end
        div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_patron_order_path(order.id), :method => :put end
        div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_patron_order_path(order.id), :method => :put, :disabled => true end
        div do "#{order.customer.full_name} is internal to UVA and requires no fee approval" end
      end
    elsif order.order_status == 'deferred'
      if order.customer.external?
        if order.fee_actual.nil?
          div :class => 'workflow_button' do button_to "Customer Accepts Fee", approve_order_patron_order_path(order.id), :disabled => 'true', :method => :put end
          div :class => 'workflow_button' do button_to "Customer Declines Fee", cancel_order_patron_order_path(order.id), :method => :put end
          div do "Please input the actual fee before approving order." end
        else
          div :class => 'workflow_button' do button_to "Customer Accepts Fee", approve_order_patron_order_path(order.id), :method => :put end
          div :class => 'workflow_button' do button_to "Customer Declines Fee", cancel_order_patron_order_path(order.id), :method => :put end
        end
      end
    elsif order.order_status == 'approved' || order.order_status == 'canceled'
      div :class => 'workflow_button' do button_to "Approve Order", approve_order_patron_order_path(order.id), :disabled => 'true', :method => :put end
      div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_patron_order_path(order.id), :disabled => 'true', :method => :put end
      div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_patron_order_path(order.id), :method => :put,  :disabled => true end
      div do "No options available.  Order is #{order.order_status}." end
    end
  end

  sidebar "Relaed Information", :only => :show do
    attributes_table_for order do
      row :units do |order|
        link_to "#{order.units.size}", patron_units_path(:q => {:order_id_eq => order.id})
      end
      row :master_files do |order|
        link_to "#{order.master_files.size}", patron_master_files_path(:q => {:order_id_eq => order.id})
      end
      row :bibls do |order|
        link_to "#{order.bibls.size}", patron_bibls_path(:q => {:orders_id_eq => order.id})
      end
      row :customer
      row :agency
    end
  end

  member_action :approve_order, :method => :put do
    begin
      order = Order.find(params[:id])
      order.update_attributes!(:order_status => "approved")
      redirect_to :back, :notice => "Order #{params[:id]} is now approved."
    rescue ActiveRecord::RecordInvalid => invalid
      redirect_to :back, :alert => "#{invalid.record.errors.full_messages.join(', ')}"
    end
  end

  member_action :cancel_order, :method => :put do
    order = Order.find(params[:id])
    order.cancel_order
    sleep(0.5)
    redirect_to :back, :notice => "Order #{params[:id]} is now canceled."
  end

  member_action :send_fee_estimate_to_customer, :method => :put do
    order = Order.find(params[:id])
    order.send_fee_estimate_to_customer(current_user.computing_id)
    sleep(0.5)
    redirect_to :back, :notice => "A fee estimate email has been sent to #{order.customer.full_name}."
  end

  controller do
    def scoped_collection
      Order.not_from_fine_arts
    end
  end
end
