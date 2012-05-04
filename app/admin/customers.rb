require 'carmen'

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
  filter :academic_status, :as => :select
  filter :department, :as => :select
  filter :heard_about_service, :as => :select
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
          div { render :partial => 'admin/attribute_table', :object => customer.primary_address }
        else
          "No address available."
        end
      end
    end

    div :class => 'three-column' do 
      panel "Billing Address", :id => 'customers' do
        if customer.billable_address
          div { render :partial => 'admin/attribute_table', :object => customer.billable_address }
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

  sidebar "Related Information", :only => [:show] do
    attributes_table_for customer do
      row :requests do |customer|
         link_to customer.requests.size.to_s, admin_orders_path(:q => {:customer_id_eq => customer.id}, :scope => 'awaiting_approval')
      end
      row :orders do |customer|
        link_to customer.orders_count.to_s, admin_orders_path(:q => {:customer_id_eq => customer.id}, :scope => 'approved')
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
end