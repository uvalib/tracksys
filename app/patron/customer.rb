ActiveAdmin.register Customer, :namespace => :patron do
  menu :priority => 2

  filter :id

  index do
    column("Name", :sortable => false) do |customer| 
      customer.full_name
    end
    column :email, :sortable => false
    column("Requests") {|customer| customer.requests.size.to_s}
    column("Orders") {|customer| customer.orders_count}
    column :academic_status, :sortable => false
    default_actions
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

  end

  form do

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
        row :organization
        row :address_1
        row :address_2
        row :city
        row :state
        row :country
        row :post_code
        row :phone
      end
    else
      "No information"
    end
  end

  controller do

  end

end