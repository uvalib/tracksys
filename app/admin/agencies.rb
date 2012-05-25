ActiveAdmin.register Agency do
  menu :parent => "Miscellaneous"

  scope :all, :default => true
  actions :all, :except => [:destroy]

  filter :id
  filter :name

  index :id => 'agencies' do 
    selectable_column
    column :name
    column :customers do |agency|
      link_to "#{agency.customers.size.to_s}", admin_customers_path(:q => {:agencies_id_eq => agency.id})
    end
    column :requests do |agency|
      link_to "#{agency.requests.size.to_s}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'awaiting_approval')
    end
    column :orders do |agency|
      link_to "#{agency.orders.size.to_s}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'approved')
    end
    column :units do |agency|
      link_to "#{agency.units.size.to_s}", admin_units_path(:q => {:agency_id_eq => agency.id})
    end
    column :bibls do |agency|
      link_to "#{agency.bibls.size.to_s}", admin_bibls_path(:q => {:agencies_id_eq => agency.id})
    end
    column :master_files do |agency|
      link_to "#{agency.master_files.size.to_s}", admin_master_files_path(:q => {:agency_id_eq => agency.id})
    end
    column :names_depth_cache
    column("Links") do |agency|
      div {link_to "Details", resource_path(agency), :class => "member_link view_link"}
      div {link_to I18n.t('active_admin.edit'), edit_resource_path(agency), :class => "member_link edit_link"}
    end
  end

  show :title => proc { agency.name } do
    panel "Detailed Information" do
      attributes_table_for agency do
        row :name
        row :description
        row :created_at do |agency|
          format_date(agency.created_at)
        end
        row :updated_at do |agency|
          format_date(agency.updated_at)
        end
      end
    end
  end

  sidebar "Related Information", :only => :show do
    attributes_table_for agency do
      row :customers do |agency|
        link_to "#{agency.customers.size.to_s}", admin_customers_path(:q => {:agency_id_eq => agency.id})
      end
      row :requests do |agency|
        link_to "#{agency.requests.size.to_s}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'awaiting_approval')
      end
      row :orders do |agency|
        link_to "#{agency.orders.size.to_s}", admin_orders_path(:q => {:agency_id_eq => agency.id}, :scope => 'approved')
      end
      row :units do |agency|
        link_to "#{agency.units.size.to_s}", admin_units_path(:q => {:agency_id_eq => agency.id})
      end
      row :bibls do |agency|
        link_to "#{agency.bibls.size.to_s}", admin_bibls_path(:q => {:agency_id_eq => agency.id})
      end
      row :master_files do |agency|
        link_to "#{agency.master_files.size.to_s}", admin_master_files_path(:q => {:agency_id_eq => agency.id})
      end
    end
  end
end