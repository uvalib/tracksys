ActiveAdmin.register Order do
  menu :priority => 3

  # strong paramters handling
  permit_params :order_status, :order_title, :special_instructions, :staff_notes, :date_request_submitted, :date_due,
     :fee_estimated, :fee_actual, :date_deferred, :date_fee_estimate_sent_to_customer, :date_permissions_given,
     :agency_id, :customer_id, :date_finalization_begun, :date_archiving_complete, :date_patron_deliverables_complete,
     :date_customer_notified, :email


  config.clear_action_items!
  action_item :new, :only => :index do
     raw("<a href='/admin/orders/new'>New</a>") if !current_user.viewer?
  end
  action_item :edit, only: :show do
     link_to "Edit", edit_resource_path  if !current_user.viewer?
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

  filter :id
  filter :agency, :as => :select, :input_html => {:'data-placeholder' => 'Choose an agency...'}
  filter :order_status, :as => :select, :collection => Order::ORDER_STATUSES
  filter :title
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
  filter :special_instructions
  filter :academic_status, :as => :select
  filter :invoices_count
  filter :master_files_count

  index :id => 'orders' do
    selectable_column
    column :id, :class => 'sortable_short'
    column ("Status") {|order| status_tag(order.order_status)}
    column :title do |order| order.title.truncate(80) unless order.title.nil? end
    column ("Special Instructions") {|order| order.special_instructions.to_s.truncate(50) }
    column ("Request Submitted"), :sortable => :date_request_submitted do|order| order.date_request_submitted.try(:strftime, "%m/%d/%y") end
    column ("Archiving Complete"), :sortable => :date_archiving_complete do |order| order.date_archiving_complete.try(:strftime, "%m/%d/%y") end
    column ("Deliverables Complete"), :sortable => :date_patron_deliverables_complete do |order| order.date_patron_deliverables_complete.try(:strftime, "%m/%d/%y") end
    column ("Customer Notified"), :sortable => :date_customer_notified do |order| order.date_customer_notified.try(:strftime, "%m/%d/%y") end
    column ("Date Due") {|order| order.date_due.try(:strftime, "%m/%d/%y")}
    column ("Units"), :sortable => :units_count, :class => 'sortable_short' do |order|
      link_to order.units_count, admin_units_path(:q => {:order_id_eq => order.id})
    end
    column ("Master Files"), :sortable => :master_files_count do |order|
      link_to order.master_files_count, admin_master_files_path(:q => {:order_id_eq => order.id})
    end
    column :agency, :sortable => 'agencies.name', :class => 'sortable_short'
    column :customer, :sortable => :"customers.last_name", :class => 'sortable_short'
    column ("Charged Fee") {|customer| number_to_currency(customer.fee_actual) }
    column("") do |order|
      div do
        link_to "Details", resource_path(order), :class => "member_link view_link"
      end
      if !current_user.viewer?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(order), :class => "member_link edit_link"
         end
      end
    end
  end

  show :title => proc{|order| "Order ##{order.id}"} do
    div :class => 'two-column' do
      panel "Basic Information" do
        attributes_table_for order do
          row :order_status do |order|
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

    div :class => 'columns-none' do
      panel "Delivery Information" do
        attributes_table_for order do
          row :date_finalization_begun do |order|
            format_date(order.date_finalization_begun)
          end
          row :date_archiving_complete do |order|
            format_date(order.date_archiving_complete)
          end
          row :date_patron_deliverables_complete do |order|
            format_date(order.date_patron_deliverables_complete)
          end
          row :date_customer_notified do |order|
            format_date(order.date_customer_notified)
          end
          row :email do |order|
            raw( strip_email(order.email) )
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

  sidebar :approval_workflow, :only => :show,  if: proc{ !current_user.viewer? } do
    if order.order_status == 'requested'
      if order.customer.external?
        if order.fee_estimated.nil?
          # External customers (who require a fee estaimte) for which there IS NO estimated fee
          div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :disabled => 'true', :method => :put end
          div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_admin_order_path(order.id), :method => :put end
          div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_admin_order_path(order.id), :disabled => true, :method => :put end
          div do "Either enter an estimated fee or cancel this order." end
        elsif order.fee_estimated
          if order.fee_actual.nil?
            # External customers (who require a fee estaimte) for which there IS estimated fee but actual fee is blank.
            # Actions available: Cancel or Send Fee Estimate
            div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :disabled => 'true', :method => :put end
            div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_admin_order_path(order.id), :method => :put end
            div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_admin_order_path(order.id), :method => :put end
            div do "Either send fee estimate or cancel this order." end
          else
            # External customers (who require a fee) for which there IS both an estimated fee and actual fee
            # Actions available: Approve or Cancel
            if order.has_units_being_prepared.any?
              div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :disabled => 'true', :method => :put end
              div do "You must approve or cancel this order's units before approving." end
            else
              div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :method => :put end
            end
            div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_admin_order_path(order.id), :method => :put end
            div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_admin_order_path(order.id), :disabled => 'true', :method => :put end
            div do "Either approve or cancel this order." end
          end
        end
     else
        # Internal customers require no fee.
        if order.has_units_being_prepared.any?
          div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :disabled => 'true', :method => :put end
          div do "You must approve or cancel this order's units before approving." end
        else
          div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :method => :put end
        end
        div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_admin_order_path(order.id), :method => :put end
        div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_admin_order_path(order.id), :method => :put, :disabled => true end
        div do "#{order.customer.full_name} is internal to UVA and requires no fee approval" end
      end
    elsif order.order_status == 'deferred'
      if order.customer.external?
        if order.fee_actual.nil?
          div :class => 'workflow_button' do button_to "Customer Accepts Fee",
          approve_order_admin_order_path(order.id), :disabled => 'true', :method => :put end
          div :class => 'workflow_button' do button_to "Customer Declines Fee", cancel_order_admin_order_path(order.id), :method => :put end
          div do "Please input the actual fee before approving order." end
        else
          div :class => 'workflow_button' do button_to "Customer Accepts Fee", approve_order_admin_order_path(order.id), :method => :put end
          div :class => 'workflow_button' do button_to "Customer Declines Fee", cancel_order_admin_order_path(order.id), :method => :put end
        end
      end
    elsif order.order_status == 'approved' || order.order_status == 'canceled'
      div :class => 'workflow_button' do button_to "Approve Order", approve_order_admin_order_path(order.id), :disabled => 'true', :method => :put end
      div :class => 'workflow_button' do button_to "Cancel Order", cancel_order_admin_order_path(order.id), :disabled => 'true', :method => :put end
      div :class => 'workflow_button' do button_to "Send Fee Estimate", send_fee_estimate_to_customer_admin_order_path(order.id), :method => :put,  :disabled => true end
      div do "No options available.  Order is #{order.order_status}." end
    end
  end

  sidebar "Delivery Workflow", :only => :show,  if: proc{ !current_user.viewer? }  do
    if order.order_status == 'approved'
      if order.email?
        div :class => 'workflow_button' do button_to "Check Order Completeness", check_order_ready_for_delivery_admin_order_path(order.id), :method => :put, :disabled => true end
        if order.date_customer_notified
          div :class => 'workflow_button' do button_to "Send Email to Customer", send_order_email_admin_order_path(order.id), :method => :put, :disabled => true end
        else
          div :class => 'workflow_button' do button_to "Send Email to Customer", send_order_email_admin_order_path(order.id), :method => :put end
        end
      else
        div :class => 'workflow_button' do button_to "Check Order Completeness", check_order_ready_for_delivery_admin_order_path(order.id), :method => :put end
        div :class => 'workflow_button' do button_to "Send Email to Customer", send_order_email_admin_order_path(order.id), :method => :put,  :disabled => true end
        div do "Order is not yet complete and cannot be delivered." end
      end
      div :class => 'workflow_button' do button_to "View Customer PDF", generate_pdf_notice_admin_order_path(order.id), :method => :put end
    else
      # order not approved
      div :class => 'workflow_button' do button_to "Check Order Completeness", check_order_ready_for_delivery_admin_order_path(order.id), :method => :put, :disabled => true end
      div :class => 'workflow_button' do button_to "Send Email to Customer", send_order_email_admin_order_path(order.id), :method => :put,  :disabled => true end
      div do "Order is not yet approved." end
    end
  end

  sidebar "Related Information", :only => :show do
    attributes_table_for order do
      row :units do |order|
        link_to "#{order.units.size}", admin_units_path(:q => {:order_id_eq => order.id})
      end
      row :master_files do |order|
        link_to "#{order.master_files.size}", admin_master_files_path(:q => {:order_id_eq => order.id})
      end
      row :sirsi_metadata do |order|
        if order.sirsi_metadata.uniq.size > 0
           link_to "#{order.sirsi_metadata.uniq.size}", "/admin/sirsi_metadata?q%5borders_id%5d=#{order.id}&scope=uniq"
        else
           0
        end
      end
      row :xml_metadata do |order|
        if order.xml_metadata.uniq.size > 0
           link_to "#{order.xml_metadata.uniq.size}", "/admin/xml_metadata?q%5borders_id%5d=#{order.id}&scope=uniq"
        else
           0
        end
      end
      row :customer
      row :agency
      row :invoices do |order|
        link_to "#{order.invoices.size}", admin_invoices_path(:q => {:order_id_eq => order.id})
      end
    end
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
end
