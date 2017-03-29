ActiveAdmin.register Invoice do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }
   config.batch_actions = false

   # strong paramters handling
   permit_params :date_invoice, :date_fee_paid, :permanent_nonpayment, :fee_amount_paid, :transmittal_number, :notes

   scope :all, :default => true
   scope :past_due
   scope :notified_past_due
   scope :permanent_nonpayment

   filter :order_id_equals, label: "Order ID"
   filter :fee_amount_paid_equals, label: "Fee Amount Paid"
   filter :notes_contains, label: "Notes"
   filter :transmittal_number_starts_with, label: "Transmittal Number"
   filter :date_invoice, :label => "Date Invoice Sent"
   filter :date_fee_paid
   filter :permanent_nonpayment

   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/invoices/new'>New</a>") if !current_user.viewer? && !current_user.student?
   end
   action_item :show, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student?
   end
   action_item :delete, only: :show do
      link_to "Delete", resource_path,
        data: {:confirm => "Are you sure you want to delete this invoice?"}, :method => :delete  if current_user.admin?
   end

   index do
      column :order
      column :order_customer
      column ("Fee") do |invoice|
         number_to_currency(invoice.order_fee_actual)
      end
      column ("Date Order Approved") do |invoice|
         format_date(invoice.order_date_order_approved)
      end
      column ("Date Customer Notified") do |invoice|
         format_date(invoice.order_date_customer_notified)
      end
      column :date_invoice do |invoice|
         format_date(invoice.date_invoice)
      end
      column ("Date Fee Paid") do |invoice|
         format_date(invoice.date_fee_paid)
      end
      column ("Date Second Notice Sent") do |invoice|
         format_date(invoice.date_second_notice_sent)
      end
      column :fee_amount_paid do |invoice|
         number_to_currency(invoice.fee_amount_paid)
      end

      column :transmittal_number
      column :permanent_nonpayment do |invoice|
         case
         when invoice.permanent_nonpayment?
            "Yes"
         end
      end
      column :notes
      column("") do |invoice|
         div do
            link_to "Details", resource_path(invoice), :class => "member_link view_link"
         end
         if !current_user.viewer? && !current_user.student?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(invoice), :class => "member_link edit_link"
            end
         end
         if current_user.admin?
            div do
               link_to "Delete", resource_path(invoice), data: {:confirm => "Are you sure you want to delete this invoice?"}, :method => :delete
            end
         end
      end
   end

   show :title => proc {|invoice| "Invoice ##{invoice.id}"} do
      div :class => 'two-column' do
         panel "Date Information" do
            attributes_table_for invoice do
               row :order_date_order_approved do |invoice|
                  format_date(invoice.order_date_order_approved)
               end
               row :order_date_customer_notified do |invoice|
                  format_date(invoice.order_date_customer_notified)
               end
               row :date_invoice do |invoice|
                  format_date(invoice.date_invoice)
               end
               row :date_fee_paid do |invoice|
                  format_date(invoice.date_fee_paid)
               end
            end
         end
      end

      div :class => 'two-column' do
         panel "Billing Information" do
            attributes_table_for invoice do
               row :permanent_nonpayment do |invoice|
                  case
                  when invoice.permanent_nonpayment?
                     "Yes"
                  end
               end
               row :fee_amount_paid do |invoice|
                  number_to_currency(invoice.fee_amount_paid)
               end
               row :transmittal_number
               row :notes
            end
         end
      end
   end

   form do |f|
      f.inputs "Date Information", :class => 'panel three-column ' do
         f.input :order_date_order_approved, :input_html => {:disabled => true}
         f.input :order_date_customer_notified, :input_html => {:disabled => true}
         f.input :date_invoice, :as => :datepicker, datepicker_options: {changeYear: true, changeMonth: true}
         f.input :date_fee_paid, :as => :date_picker
      end

      f.inputs "Billing Information", :class => 'three-column panel' do
         f.input :permanent_nonpayment, :as=>:boolean, :input_html => {:style => 'width:100%' }
         f.input :fee_amount_paid, :as => :string
         f.input :transmittal_number, :as => :string
         f.input :notes, :input_html => {:rows => 5}
      end

      f.inputs "Related Information", :class => 'panel three-column' do
         f.input :order_id, :input_html => {:disabled => true}
      end

      f.inputs :class => 'columns-none' do
         f.actions
      end
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for invoice do
         row ("Order") do |invoice|
            link_to "##{invoice.order_id}", admin_order_path(invoice.order_id)
         end
      end
   end

   member_action :get_pdf do
      invoice = Invoice.find(params[:id])
      send_data invoice.invoice_copy, :filename => "order_#{invoice.order_id}.pdf", :type => 'application/pdf'
   end

   csv do
      column ("Date Fee Paid") { |invoice| format_date(invoice.date_fee_paid) }
      column ("Fee") { |invoice| invoice.order_fee_actual }
      column :order_id
      column :notes
   end
end
