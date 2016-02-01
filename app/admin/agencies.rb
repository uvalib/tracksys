ActiveAdmin.register Agency do
  menu :parent => "Miscellaneous"

  config.sort_order = 'name_asc'

  scope :all, :default => true
  scope :no_parent

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
    column :descendants do |agency|
      # agency.descendants.map(&:names_depth_cache).map {|cache| cache.gsub("#{agency.name}/", '')}.sort || "N/A"
      agency.children.sort_by(&:name).each {|child|
        div do link_to "#{child.name}", admin_agency_path(child) end
      }
    end
    column "Parents" do |agency|
      agency.ancestors.each {|ancestor|
        div do link_to "#{ancestor.name}", admin_agency_path(ancestor) end
      }
    end
    column("Links") do |agency|
      div {link_to "Details", resource_path(agency), :class => "member_link view_link"}
      div {link_to I18n.t('active_admin.edit'), edit_resource_path(agency), :class => "member_link edit_link"}
    end
  end

  show do
    panel "Detailed Information" do
      attributes_table_for agency do
        row :name
        row :description
        row :parent do |agency|
          agency.ancestors.each {|ancestor|
            div do link_to "#{ancestor.name}", admin_agency_path(ancestor) end
          } unless agency.ancestors.empty?
        end
        row :children do |agency|
          agency.children.sort_by(&:name).each {|child|
            div do link_to "#{child.name}", admin_agency_path(child) end
          } unless agency.children.empty?
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

  sidebar "Agency and Descendant Counts", :only => :show do
    attributes_table_for agency do
      row :customers do |agency|
        agency.total_class_count('customers')
      end
      row :requests do |agency|
        agency.total_class_count('requests')
      end
      row :orders do |agency|
        agency.total_class_count('orders')
      end
      row :units do |agency|
        agency.total_class_count('units')
      end
      row :bibls do |agency|
        agency.total_class_count('bibls')
      end
      row :master_files do |agency|
        agency.total_class_count('master_files')
      end
    end
  end

  sidebar "Agency Related Information", :only => :show do
    attributes_table_for agency do
      row :customers do |agency|
        link_to "#{agency.customers.size.to_s}", admin_customers_path(:q => {:agencies_id_eq => agency.id})
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
        link_to "#{agency.bibls.size.to_s}", admin_bibls_path(:q => {:agencies_id_eq => agency.id})
      end
      row :master_files do |agency|
        link_to "#{agency.master_files.size.to_s}", admin_master_files_path(:q => {:agency_id_eq => agency.id})
      end
    end
  end

  form do |f|
    f.inputs "Agency Information", :class => 'panel' do
      f.input :name
      f.input :description
      f.input :parent_id, :as => :select, :collection => Agency.order(:names_depth_cache).map {|a| ["    |---- " * a.depth + a.name,a.id]}.insert(0, ""), :include_blank => true, :input_html => {:class => 'chzn-select-deselect'}, :label => "Parent Agency"
    end

    f.inputs :class => 'columns-none' do
      f.actions
    end
  end

  # controller do
  #   caches_action :index, :unless => Proc.new { |c| c.params.include?(:page) || c.params.include?(:q) }
  #   caches_action :show
  #   cache_sweeper :agencies_sweeper
  # end
end
