ActiveAdmin.register Invoice do
  menu :parent => "Miscellaneous"

  scope :all, :default => true

  filter :order_id, :as => :numeric
  filter :fee_amount_paid
  filter :notes
  filter :transmittal_number
  filter :date_invoice, :label => "Date Invoice Sent"

  index do
    column :order
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
    column :notes
    column ("PDF of Invoice") do |invoice|
      link_to "Download", get_pdf_admin_invoice_path(invoice.id), :method => :get
    end
    column("") do |invoice|
      div do
        link_to "Details", resource_path(invoice), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(invoice), :class => "member_link edit_link"
      end
    end
  end

  show :title => proc {"Invoice ##{invoice.id}"} do
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
          row :fee_amount_paid do |invoice|
            number_to_currency(invoice.fee_amount_paid)
          end
          row :transmittal_number
          row :notes
          row ("PDF") do |invoice|
            link_to "Download", get_pdf_admin_invoice_path(invoice.id), :method => :get
          end
          row("Old type invoice (if available)") do |invoice|
            raw(invoice.invoice_content)
          end
        end
      end
    end
  end

  form do |f|
    f.inputs "Date Information", :class => 'panel three-column ' do
      f.input :order_date_order_approved, :input_html => {:disabled => true}
      f.input :order_date_customer_notified, :input_html => {:disabled => true}
      f.input :date_invoice, :as => :datepicker
      f.input :date_fee_paid, :as => :datepicker
    end

    f.inputs "Billing Information", :class => 'three-column panel' do
      f.input :fee_amount_paid, :as => :string
      f.input :transmittal_number, :as => :string
      f.input :notes, :input_html => {:rows => 3}
      f.input :invoice_content, :input_html => {:rows => 5}
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
end
