require 'carmen'

ActiveAdmin.register Customer do
  menu :priority => 2

  actions :all, :except => [:destroy]

  scope :all, :default => true
  
  filter :first_name
  filter :last_name
  filter :email
  filter :academic_status
  filter :orders_count
  filter :master_files_count

  index do

    column("Name", :sortable => false) do |customer| 
      customer.full_name
    end
    column :email, :sortable => false
    column("Requests") {|customer| customer.requests.size.to_s}
    column("Orders") {|customer| customer.orders_count}
    column("Units") {|customer| customer.units.size.to_s }
    column("Bibliographic Records") {|customer| customer.bibls.size.to_s}
    column("Master Files") do |customer|
      link_to customer.master_files.size.to_s, "master_files?q%5Bcustomer_id_eq%5D=#{customer.id}&order=filename_asc"
#      link_to customer.master_files.size.to_s, admin_master_files_path(customer.master_files)
    end
    column :academic_status, :sortable => false
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
      f.input :post_code
      f.input :country, :collection => Carmen.country_names, :priority_countries => ['US']
      f.input :heard_about_service, :as => :select, :collection => HeardAboutService.where(:is_approved => true)
    end
    f.buttons
  end

  show :title => proc { customer.full_name } do
    panel "Orders" do
      div :id => "orders" do
        collection = customer.orders.page(params[:order_page])
        pagination_options = {:entry_name => Order.model_name.human, :param_name => :order_page, :download_links => false}
        paginated_collection(collection, pagination_options) do
          table_options = {:id => 'orders-table', :sortable => true, :class => "order_index_table"}
          table_for collection, table_options do
            column :id do |order|
              link_to "#{order.id}", admin_order_path(order)
            end
            column("Status") {|order| status_tag(order.order_status)}
            column :date_request_submitted do |order|
              format_date(order.date_request_submitted)
            end
            column :date_order_approved do |order|
              format_date(order.date_order_approved)
            end
            column :date_archiving_complete do |order|
              format_date(order.date_archiving_complete)
            end
            column :date_patron_deliverables_complete do |order|
              format_date(order.date_patron_deliverables_complete)
            end
            column :date_customer_notified do |order|
              format_date(order.date_customer_notified)
            end
            column :date_due do |order|
              format_date(order.date_due)
            end
            column :agency, :sortable => false
            column :units_count, :sortable => false
            column :master_files_count do |order|
              order.master_files.count
            end
          end
        end
      end
    end

    panel "Units" do
      div :id => "units" do
        collection = customer.units.page(params[:unit_page])
        pagination_options = {:entry_name => Unit.model_name.human, :param_name => :unit_page, :download_links => false}
        paginated_collection(collection, pagination_options) do
          table_options = {:id => 'units-table', :sortable => true, :class => "unit_index_table", :i18n => Unit}
          table_for collection, table_options do
            column("ID") {|unit| link_to "#{unit.id}", admin_unit_path(unit) }
            column :order, :sortable => false
            column :unit_status, :sortable => false
            column :bibl, :sortable => false
            column :bibl_call_number, :sortable => false
            column :date_archived do |unit|
              format_date(unit.date_archived)
            end
            column :date_dl_deliverables_ready do |unit|
              format_date(unit.date_dl_deliverables_ready)
            end
            column("# of Master Files") {|unit| unit.master_files_count.to_s}
          end
        end
      end
    end

    panel "Bibliographic Records" do
      div :id => "bibls" do
        collection = customer.bibls.page(params[:bibl_page])
        pagination_options = {:entry_name => Bibl.model_name.human, :param_name => :bibl_page, :download_links => false}
        paginated_collection(collection, pagination_options) do
          table_options = {:id => 'bibls-table', :sortable => true, :class => "bibls_index_table", :i18n => Bibl}
          table_for collection, table_options do
            column ("ID") {|bibl| link_to "#{bibl.id}", admin_bibl_path(bibl)}
            column :call_number
            column ("Catalog Key") {|bibl| bibl.catalog_key.to_s}
            column :barcode
            column :title
            column :creator_name
          end
        end
      end
    end
  end

  sidebar "Customer Details", :only => :show do
    attributes_table_for customer do
      row :full_name
      row :email do |customer|
        format_email_in_sidebar(customer.email).gsub(/\s/, "")
      end
      row :date_of_first_order do |customer|
        format_date(customer.date_of_first_order)
      end
      row :academic_status
   end
  sidebar "Primary Address", :only => :show do
    attributes_table_for customer.primary_address do
      row :organization
      row :address_1
      row :address_2
      row :city
      row :state
      row :country
      row :post_code
      row :phone
    end
  end
  
  sidebar "Billable Address", :only => :show do
    if customer.billable_address
      attributes_table_for customer.billable_address do
        row :last_name
        row :first_name
        row :agency
        row :organization
        row :address_1
        row :address_2
        row :city
        row :state
        row :country
        row :post_code
        row :phone
        row :created_at do |customer|
          format_date(customer.created_at)
        end
        row :updated_at do |customer|
          format_date(customer.updated_at)
        end
      end
    else
      "No information"
    end
  end
end
