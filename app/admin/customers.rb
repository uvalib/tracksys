ActiveAdmin.register Customer do
  menu :priority => 2

  actions :all, :except => [:destroy]

  scope :all, :default => true
  
  filter :id
  filter :first_name
  filter :last_name
  filter :email
  filter :primary_address_organization, :as => :string, :label => "Primary Organization"
  filter :billable_address_organization, :as => :string, :label => "Billable Organization"
  filter :academic_status, :as => :select, :input_html => {:class => 'chzn-select'}
  filter :department, :as => :select, :input_html => {:class => 'chzn-select'}
  filter :heard_about_service, :as => :select, :input_html => {:class => 'chzn-select'}
  filter :heard_about_resources_id, :as => :numeric
  filter :orders_count
  filter :master_files_count
  filter :agencies_id, :as => :numeric

  index :as => :table do
    selectable_column
    column("Name", :sortable => false) do |customer| 
      customer.full_name
    end
    column :requests do |customer|
       link_to customer.requests.size.to_s, admin_orders_path(:q => {:customer_id_eq => customer.id}, :scope => 'awaiting_approval')
    end
    column :orders do |customer|
      link_to customer.orders_count.to_s, admin_orders_path(:q => {:customer_id_eq => customer.id}, :scope => 'approved')
    end
    column :units do |customer| 
      link_to customer.units.size.to_s, admin_units_path(:q => {:customer_id_eq => customer.id})
    end
    column ("Bibliographic Records") do |customer| 
      link_to customer.bibls.size.to_s, admin_bibls_path(:q => {:customers_id_eq => customer.id}) # Bibl requires 'customers_id' since there are potentially many customers for each bibl
    end
    column :master_files do |customer|
      link_to customer.master_files_count.to_s, admin_master_files_path(:q => {:customer_id_eq => customer.id})
    end
    column :department, :sortable => false
    column :academic_status, :sortable => false
    column("Links") do |customer|
      div do
        link_to "Details", resource_path(customer), :class => "member_link view_link"
      end
      div do
        link_to I18n.t('active_admin.edit'), edit_resource_path(customer), :class => "member_link edit_link"
      end
    end
  end

  show :title => proc { customer.full_name } do
    div :class => 'three-column' do 
      panel "Details", :id => 'customers' do
        attributes_table_for customer do
          row :full_name
          row :email do |customer|
            format_email_in_sidebar(customer.email).gsub(/\s/, "")
          end
          row :academic_status
          row :heard_about_service
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
            row :first_name
            row :last_name
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
  end

  form do |f|
    f.object.build_primary_address unless customer.primary_address
    f.object.build_billable_address unless customer.billable_address
    f.inputs "Details", :class => 'inputs three-column' do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :academic_status, :as => :select, :input_html => {:class => 'chzn-select'}
      f.input :heard_about_service, :as => :select, :collection => HeardAboutService.where(:is_approved => true), :input_html => {:class => 'chzn-select'}
      f.input :department, :as => :select, :collection => Department.order(:name), :input_html => {:class => 'chzn-select', :style => 'width: 250px'}
    end

    f.inputs "Primary Address (Required)", :class => 'inputs three-column' do
      f.semantic_fields_for :primary_address do |p|
        p.inputs do
          p.input :address_1
          p.input :address_2
          p.input :city
          p.input :state
          p.input :country, :as => :country, :priority_countries => ['United States', 'Canada'], :include_blank => true, :input_html => {:class => 'chzn-select'}
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
          b.input :state
          b.input :country, :as => :country, :priority_countries => ['United States', 'Canada'], :include_blank => true, :input_html => {:class => 'chzn-select'}
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

  sidebar "Related Information", :only => [:show] do
    attributes_table_for customer do
      row :requests do |customer|
         link_to customer.requests.size.to_s, admin_orders_path(:q => {:customer_id_eq => customer.id}, :scope => 'awaiting_approval')
      end
      row :orders do |customer|
        link_to customer.orders_count.to_s, admin_orders_path(:q => {:customer_id_eq => customer.id})
      end
      row :units do |customer| 
        link_to customer.units.size.to_s, admin_units_path(:q => {:customer_id_eq => customer.id})
      end
      row ("Bibliographic Records") do |customer| 
        link_to customer.bibls.size.to_s, admin_bibls_path(:q => {:customers_id_eq => customer.id}) # Bibl requires 'customers_id' since there are potentially many customers for each bibl
      end
      row :master_files do |customer|
        link_to customer.master_files_count.to_s, admin_master_files_path(:q => {:customer_id_eq => customer.id})
      end
      row :date_of_first_order do |customer|
        format_date(customer.date_of_first_order)
      end
    end
  end

  controller do
    # Only cache the index view if it is the base index_url (i.e. /customers) and is devoid of either params[:page] or params[:q].  
    # The absence of these params values ensures it is the base url.
    caches_action :index, :unless => Proc.new { |c| c.params.include?(:page) || c.params.include?(:q) }
    caches_action :show
    cache_sweeper :customers_sweeper
  end
end