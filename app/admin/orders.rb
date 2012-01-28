ActiveAdmin.register Order do
  menu :priority => 3

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

  index do
    column :id
    column ("Status") {|order| status_tag(order.order_status)}
    column ("Date Request Submitted") {|order| order.date_request_submitted.try(:strftime, "%m/%d/%y")}
    column ("Date Order Approved") {|order| order.date_order_approved.try(:strftime, "%m/%d/%y")}
    column ("Date Archiving Complete") {|order| order.date_archiving_complete.try(:strftime, "%m/%d/%y")}
    column ("Date Patron Deliverables Complete") {|order| order.date_patron_deliverables_complete.try(:strftime, "%m/%d/%y")}
    column ("Date Customer Notified") {|order| order.date_customer_notified.try(:strftime, "%m/%d/%y")}
    column ("Date Due") {|order| order.date_due.try(:strftime, "%m/%d/%y")}
    column :agency
    column :customer
    default_actions
  end

  show do
    panel "Units" do
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

    panel "Automation Messages" do
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

  sidebar :customer, :only => [:edit, :show] do
    attributes_table_for order.customer do
      row("Name") {link_to "#{order.customer_full_name}", admin_customer_path(order.customer)}
      row :email
    end
  end

  sidebar :agency, :only => [:edit, :show] do
    attributes_table_for order.agency do
      row("Name") {auto_link order.agency_name}
    end
  end
end
