require 'carmen'

ActiveAdmin.register Customer do
  menu :priority => 2

  actions :all, :except => [:destroy]

  scope :all, :default => true
  
  filter :first_name
  filter :last_name
  filter :email
  filter :primary_address_organization, :as => :string, :label => "Primary Organization"
  filter :billable_address_organization, :as => :string, :label => "Billable Organization"
  filter :department, :collection => proc { Department.order(:name)}
  filter :academic_status, :collection => proc { AcademicStatus.order(:name) }
  filter :heard_about_service, :collection => proc { HeardAboutService.order(:description) }
  filter :orders_count
  filter :master_files_count

  index :id => 'customers' do
    column("Name", :sortable => false) do |customer| 
      customer.full_name
    end
    column("Requests") {|customer| customer.requests.size.to_s}
    column("Orders") {|customer| customer.orders_count}
    column("Units") do|customer| 
      link_to customer.units.size.to_s, "units?q%5Bcustomers_id_eq%5D=#{customer.id}"
    end
    column("Bibliographic Records") do |customer| 
      link_to customer.bibls.size.to_s, "bibls?q%5Bcustomers_id_eq%5D=#{customer.id}"
    end
    column("Master Files") do |customer|
      link_to customer.master_files.size.to_s, "master_files?q%5Bcustomer_id_eq%5D=#{customer.id}"
    end
    column :department, :sortable => false
    column :academic_status, :sortable => false
    default_actions
  end

  form do |f|
    f.object.build_primary_address unless customer.primary_address
    f.object.build_billable_address unless customer.billable_address
    f.inputs "Details", :class => 'inputs three-column' do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :academic_status, :as => :select, :collection => AcademicStatus.order(:name)
      f.input :heard_about_service, :as => :select, :collection => HeardAboutService.where(:is_approved => true)
      f.input :department, :as => :select, :collection => Department.order(:name)
    end

    f.inputs "Primary Address (Required)", :class => 'inputs three-column' do
      f.semantic_fields_for :primary_address do |p|
        p.inputs do
          p.input :address_1
          p.input :address_2
          p.input :city
          p.input :state, :as => :select, :collection => Carmen.state_codes('US')
          p.input :country, :as => :country, :collection => Carmen.country_codes, :priority_countries => ['US'], :include_blank => true
          p.input :post_code
          p.input :phone
          p.input :organization 
        end
      end
    end

    f.inputs "Billable Address (Optional)", :class => 'inputs three-column' do
      f.semantic_fields_for :billable_address do |b|
        b.inputs do 
          b.input :first_name
          b.input :last_name
          b.input :address_1
          b.input :address_2
          b.input :city
          b.input :state, {:collection => Carmen::state_codes('US'), :include_blank => true}
          b.input :country, :as => :country, :collection => Carmen.country_codes, :priority_countries => ['US'], :include_blank => true
          b.input :post_code
          b.input :phone
          b.input :organization
        end
      end
    end

    f.inputs :class => 'columns-none' do
      f.actions 
    end
  end

  show :title => proc { customer.full_name } do
    div :class => 'three-column' do 
      panel "Customer Details", :id => 'customers' do
        attributes_table_for customer do
          row :full_name
          row :email do |customer|
            format_email_in_sidebar(customer.email).gsub(/\s/, "")
          end
          row :date_of_first_order do |customer|
            format_date(customer.date_of_first_order)
          end
          row :academic_status
          row :department
        end
      end
    end

    div :class => 'three-column' do
      panel "Primary Address", :id => 'customers' do
        if customer.primary_address
          attributes_table_for customer.primary_address do
            row :address_1
            row :address_2
            row :city
            row :state
            row :country
            row :post_code
            row :phone
            row :organization
          end
        else
          "No address available."
        end
      end
    end

    div :class => 'three-column' do 
      panel "Billing Address", :id => 'customers' do
        if customer.billable_address
          attributes_table_for customer.billable_address do
            row :last_name
            row :first_name
            row :organization
            row :address_1
            row :address_2
            row :city
            row :state
            row :country
            row :post_code
            row :phone
            row :organization
          end
        else
          "No address available."
        end
      end
    end

    div :class => 'columns-none' do
      div :id => "requests" do
        panel "Requests (#{customer.requests.count})", :id => 'orders', :toggle => 'hide' do
          collection = customer.requests.page(params[:requests_page])
          pagination_options = {:entry_name => Request.model_name.human, :param_name => :order_page, :download_links => false}
          paginated_collection(collection, pagination_options) do
              table_options = {:id => 'requests-table', :sortable => true, :class => "order_index_table"}
              table_for collection, table_options do
                column :id do |request|
                  link_to "#{request.id}", admin_order_path(request)
                end
                column("Status") {|request| status_tag(request.order_status)}
                column :date_request_submitted do |request|
                  format_date(request.date_request_submitted)
                end
                column :date_order_approved do |request|
                  format_date(request.date_order_approved)
                end
                column :date_archiving_complete do |request|
                  format_date(request.date_archiving_complete)
                end
                column :date_patron_deliverables_complete do |request|
                  format_date(request.date_patron_deliverables_complete)
                end
                column :date_customer_notified do |request|
                  format_date(request.date_customer_notified)
                end
                column :date_due do |request|
                  format_date(request.date_due)
                end
                column :agency, :sortable => false
                column :units_count, :sortable => false
              end
            end
          end
        end

      panel "Orders (#{customer.orders_count})", :id => 'orders', :toggle => 'hide' do
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

      panel "Units (#{customer.units.count})", :id => 'units', :toggle => "hide" do
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

      panel "Bibliographic Records (#{customer.bibls.count})", :id => 'bibls', :toggle => "hide" do
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
  end
end
