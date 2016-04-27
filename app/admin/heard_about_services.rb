ActiveAdmin.register HeardAboutService do
  menu :parent => "Miscellaneous"

  # strong paramters handling
  permit_params :description, :is_approved, :is_internal_use_only

  config.clear_action_items!
  action_item :new, :only => :index do
     raw("<a href='/admin/heard_about_services/new'>New</a>") if !current_user.viewer?
  end
  action_item :show, only: :show do
     link_to "Edit", edit_resource_path  if !current_user.viewer?
  end

  filter :description
  filter :is_approved, :as => :select
  filter :is_internal_use_only, :as => :select

  scope :all, :default => true
  scope :approved
  scope :not_approved
  scope :internal_use_only
  scope :publicly_available

  index do
    column :description
    column :customers do |heard_about_service|
      link_to "#{heard_about_service.customers.count}", admin_customers_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
    end
    column :orders do |heard_about_service|
      link_to "#{heard_about_service.orders.count}", admin_orders_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
    end
    column :units do |heard_about_service|
      link_to "#{heard_about_service.units.count}", admin_units_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
    end
    column :master_files do |heard_about_service|
      link_to "#{heard_about_service.master_files.count}", admin_master_files_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
    end
    column ("Approved?") do |heard_about_service|
      format_boolean_as_yes_no(heard_about_service.is_approved)
    end
    column ("Internal Use Only?") do |heard_about_service|
      format_boolean_as_yes_no(heard_about_service.is_internal_use_only)
    end
    column("") do |heard_about_service|
      div do
        link_to "Details", resource_path(heard_about_service), :class => "member_link view_link"
      end
      if !current_user.viewer?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(heard_about_service), :class => "member_link edit_link"
         end
      end
    end
  end

  show :title => proc { |service| service.description } do
    panel "Detailed Information" do
      attributes_table_for heard_about_service do
        row :description
        row ("Approved?") do |heard_about_service|
          format_boolean_as_yes_no(heard_about_service.is_approved)
        end
        row ("Internal Use Only?") do |heard_about_service|
          format_boolean_as_yes_no(heard_about_service.is_internal_use_only)
        end
        row :created_at do |heard_about_service|
          format_date(heard_about_service.created_at)
        end
        row :updated_at do |heard_about_service|
          format_date(heard_about_service.updated_at)
        end
      end
    end
  end

  sidebar "Related Information", :only => :show do
    attributes_table_for heard_about_service do
      row :customers do |heard_about_service|
        link_to "#{heard_about_service.customers.count}", admin_customers_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
      end
      row :orders do |heard_about_service|
        link_to "#{heard_about_service.orders.count}", admin_orders_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
      end
      row :units do |heard_about_service|
        link_to "#{heard_about_service.units.count}", admin_units_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
      end
      row :master_files do |heard_about_service|
        link_to "#{heard_about_service.master_files.count}", admin_master_files_path(:q => {:heard_about_service_id_eq => heard_about_service.id})
      end
    end
  end

end
