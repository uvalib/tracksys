ActiveAdmin.register Customer do
  menu :priority => 2

  scope :all, :default => true
  
  filter :last_name
  filter :first_name
  filter :email
  filter :heard_about_service

  index do
    # TODO: Need to continue investigating how to multi-sort.  Want to sort by last_name and first_name
    column("Name", :sortable => false) {|customer| customer.full_name}
    column :email, :sortable => false
    column("Requests") {|customer| customer.requests.count.to_s}
    column("Orders") {|customer| customer.orders.count.to_s}
    column("Units") {|customer| customer.units.count.to_s }
    column("Bibliographic Records") {|customer| customer.bibls.count.to_s}
    column("MasterFiles") {|customer| customer.master_files.count.to_s }
    column :heard_about_service, :sortable => false
    default_actions
  end

  form do |f|
    f.inputs "Details" do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :address_1
      f.input :address_2
      f.input :city
      f.input :state, :collection => Carmen::state_codes('US')
      f.input :country, :collection => Carmen.country_names, :priority_countries => ['US']
      f.input :heard_about_service, :as => :select, :collection => HeardAboutService.where(:is_approved => true)
    end
    f.buttons
  end

  show :title => proc { customer.full_name } do
    panel "Orders" do
      table_for(customer.orders) do
        column("ID") {|order| link_to "#{order.id}", admin_order_path(order)}
        column ("Status") {|order| status_tag(order.order_status)}
        column :date_request_submitted
        column :date_order_approved
        column :date_archiving_complete
        column :date_patron_deliverables_complete
        column :date_customer_notified
        column :date_due
        column :agency
       end
     end

    panel "Units" do
      table_for (customer.units) do
        column("ID") {|unit| link_to "#{unit.id}", admin_unit_path(unit) }
        column :unit_status
        column :bibl_title
        column :bibl_call_number
        column :date_archived
        column :date_dl_deliverables_ready
        column("# of Master Files") {|unit| unit.master_files_count.to_s}
      end
    end

    panel "Bibliographic Records" do
      table_for (customer.bibls) do
        column :id
        column :call_number
        column :title
      end
    end
  end

  sidebar "Customer Details", :only => :show do
    attributes_table_for customer, :email, :organization, :address_1, :address_2, :city, :state, :country, :post_code, :date_of_first_order, :heard_about_service
  end

  sidebar "Billing Address", :only => :show do
    if customer.billing_address
      attributes_table_for customer.billing_address, :last_name, :first_name, :agency, :organization, :address_1, :address_2, :city, :state, :country, :post_code, :phone, :created_at, :updated_at
    end
  end
end

