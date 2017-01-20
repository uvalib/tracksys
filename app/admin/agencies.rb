ActiveAdmin.register Agency do
  menu :parent => "Miscellaneous"
  config.batch_actions = false

  # strong paramters handling
  permit_params :name, :description, :parent_id

  config.sort_order = 'name_asc'

  scope :all, :default => true
  scope :no_parent

  config.clear_action_items!
  action_item :new, :only => :index do
     raw("<a href='/admin/agencies/new'>New</a>") if current_user.admin?
  end
  action_item :edit, only: :show do
     link_to "Edit", edit_resource_path  if current_user.admin?
  end

  filter :id
  filter :name

  index :id => 'agencies' do
    selectable_column
    column :name
    column :customers do |agency|
      link_to "#{agency.customers.count}", admin_customers_path(:q => {:agencies_id_eq => agency.id})
    end
    column :requests do |agency|
      link_to "#{agency.requests.count}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'awaiting_approval')
    end
    column :orders do |agency|
      link_to "#{agency.orders.count}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'approved')
    end
    column :units do |agency|
      link_to "#{agency.units.count}", admin_units_path(:q => {:agency_id_eq => agency.id})
    end
    column :master_files do |agency|
      link_to "#{agency.master_files.count}", admin_master_files_path(:q => {:agency_id_eq => agency.id})
    end
    column :descendants do |agency|
      raw(agency.descendant_links)
    end
    column "Parents" do |agency|
      raw(agency.parent_links)
    end
    column("Links") do |agency|
      div {link_to "Details", resource_path(agency), :class => "member_link view_link"}
      if current_user.admin?
         div {link_to I18n.t('active_admin.edit'), edit_resource_path(agency), :class => "member_link edit_link"}
      end
    end
  end

  show do
    panel "Detailed Information" do
      attributes_table_for agency do
        row :name
        row :description
        row :parent do |agency|
          raw(agency.parent_links)
        end
        row :children do |agency|
          raw(agency.descendant_links)
        end
        row :created_at do |agency|
          format_date(agency.created_at)
        end
        row :updated_at do |agency|
          format_date(agency.updated_at)
        end
      end
    end
  end

  sidebar "Agency Related Information", :only => :show do
    attributes_table_for agency do
      row :customers do |agency|
        link_to "#{agency.customers.count}", admin_customers_path(:q => {:agencies_id_eq => agency.id})
      end
      row :requests do |agency|
        link_to "#{agency.requests.count}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'awaiting_approval')
      end
      row :orders do |agency|
        link_to "#{agency.orders.count}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'approved')
      end
      row :units do |agency|
        link_to "#{agency.units.count}", admin_units_path(:q => {:agency_id_eq => agency.id})
      end
      row :master_files do |agency|
        link_to "#{agency.master_files.count}", admin_master_files_path(:q => {:agency_id_eq => agency.id})
      end
    end
  end

  form do |f|
    f.inputs "Agency Information", :class => 'panel' do
      f.input :name
      f.input :description
      f.input :parent_id, :as => :select, :collection => Agency.order(:names_depth_cache).map {|a| ["    |---- " * a.depth + a.name,a.id]}.insert(0, ""), :include_blank => true, :label => "Parent Agency"
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end
  end
end
