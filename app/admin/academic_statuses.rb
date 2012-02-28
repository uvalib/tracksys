ActiveAdmin.register AcademicStatus do
  menu :parent => "Miscellaneous"

  index do
    column("Name") do |academic_status|
      link_to "#{academic_status.name}", admin_academic_status_path(academic_status)
    end
    column :customers_count
    column :created_at do |academic_status|
      format_date(academic_status.created_at)
    end
    column :updated_at do |academic_status|
      format_date(academic_status.updated_at)
    end
  end 

  show :title => proc { academic_status.name } do
    panel "Customers" do
      div :id => 'customers' do
        collection = academic_status.customers.page(params[:customer_page])
        pagination_options = {:entry_name => Customer.model_name.human, :param_name => :customer_page, :download_links => false}
        paginated_collection(collection, pagination_options) do
          table_options = {:id => 'customers-table', :sortable => true, :class => "customer_index_table"}
          table_for collection, table_options do
            column :name do |customer|
              link_to "#{customer.full_name}", admin_customer_path(customer)
            end
            column :email
            column("Requests") {|customer| customer.requests.size.to_s}
            column("Orders") {|customer| customer.orders_count}
            column("Units") {|customer| customer.units.size.to_s }
            column("Bibliographic Records") {|customer| customer.bibls.size.to_s}
            column("Master Files") do |customer|
              link_to customer.master_files.size.to_s, "master_files?q%5Bcustomer_id_eq%5D=#{customer.id}&order=filename_asc"
            end
          end
        end
      end
    end
  end

  sidebar "Orders Complete By Year", :only => :show do
    attributes_table_for academic_status do
      row("2011") {|academic_status| academic_status.orders.where(:date_archiving_complete => '2011-01-01'..'2011-12-31').count }
      row("2010") {|academic_status| academic_status.orders.where(:date_archiving_complete => '2010-01-01'..'2010-12-31').count }
      row("2009") {|academic_status| academic_status.orders.where(:date_archiving_complete => '2009-01-01'..'2009-12-31').count }
    end
  end
  
end
