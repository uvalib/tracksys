ActiveAdmin.register Department do
  menu :parent => "Miscellaneous"

  filter :id
  filter :name

  config.clear_action_items!
  action_item :new, :only => :index do
     raw("<a href='/admin/departments/new'>New</a>") if !current_user.viewer?
  end
  action_item :edit, only: :show do
     link_to "Edit", edit_resource_path  if !current_user.viewer?
  end

  scope :all, :default => true

  index do
    column :name
    column :customers do |department|
      link_to "#{department.customers.size.to_s}", admin_customers_path(:q => {:department_id_eq => department.id})
    end
    column :requests do |department|
      link_to "#{department.requests.size.to_s}", admin_orders_path(:q => {:department_id_eq => department.id, :scope => 'awaiting_approval'})
    end
    column :orders do |department|
      link_to "#{department.orders.size.to_s}", admin_orders_path(:q => {:department_id_eq => department.id, :scope => 'approved'})
    end
    column :units do |department|
      link_to "#{department.units.size.to_s}", admin_units_path(:q => {:department_id_eq => department.id})
    end
    column :master_files do |department|
      link_to "#{department.master_files.size.to_s}", admin_master_files_path(:q => {:department_id_eq => department.id})
    end
    column :created_at do |department|
      format_date(department.created_at)
    end
    column :updated_at do |department|
      format_date(department.updated_at)
    end
    column("") do |department|
      div do
        link_to "Details", resource_path(department), :class => "member_link view_link"
      end
      if !current_user.viewer?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(department), :class => "member_link edit_link"
         end
      end
    end
  end

  show do
    panel "Detailed Information" do
      attributes_table_for department do
        row :name
        row :created_at do |department|
          format_date(department.created_at)
        end
        row :updated_at do |department|
          format_date(department.updated_at)
        end
      end
    end
  end

  sidebar "Related Information", :only => :show do
    attributes_table_for department do
      row :customers do |department|
        link_to "#{department.customers.size.to_s}", admin_customers_path(:q => {:department_id_eq => department.id})
      end
      row :requests do |department|
        link_to "#{department.requests.size.to_s}", admin_orders_path(:q => {:department_id_eq => department.id, :scope => 'awaiting_approval'})
      end
      row :orders do |department|
        link_to "#{department.orders.size.to_s}", admin_orders_path(:q => {:department_id_eq => department.id, :scope => 'approved'})
      end
      row :units do |department|
        link_to "#{department.units.size.to_s}", admin_units_path(:q => {:department_id_eq => department.id})
      end
      row :master_files do |department|
        link_to "#{department.master_files.size.to_s}", admin_master_files_path(:q => {:department_id_eq => department.id})
      end
    end
  end

  sidebar "Orders Complete By Year", :only => :show do
    attributes_table_for department do
      row("2011") {|department| department.orders.where(:date_archiving_complete => '2011-01-01'..'2011-12-31').count }
      row("2010") {|department| department.orders.where(:date_archiving_complete => '2010-01-01'..'2010-12-31').count }
      row("2009") {|department| department.orders.where(:date_archiving_complete => '2009-01-01'..'2009-12-31').count }
    end
  end

end
