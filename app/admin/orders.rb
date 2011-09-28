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
    column :date_request_submitted
    column :date_order_approved
    column :date_archiving_complete
    column :date_patron_deliverables_complete
    column :date_customer_notified
    column :date_due
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
