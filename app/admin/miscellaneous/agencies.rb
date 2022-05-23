ActiveAdmin.register Agency do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }
   config.batch_actions = false
   config.per_page = [30, 50, 100, 250]

   # strong paramters handling
   permit_params :name, :description, :parent_id

   config.sort_order = 'name_asc'

   filter :name_starts_with, label: "Name"

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
      column("") do |agency|
         div do
           link_to "Details", resource_path(agency), :class => "member_link view_link"
         end
      end
   end

   show :title => proc { |agency| agency.name } do
      panel "Detailed Information" do
        attributes_table_for agency do
          row :name
          row :description
        end
      end
    end

   form do |f|
      f.inputs "Agency Information", :class => 'panel' do
         f.input :name
         f.input :description
      end

      f.inputs :class => 'columns-none' do
         f.actions
      end
   end
end
