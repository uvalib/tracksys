ActiveAdmin.register Customer do
   # menu :priority => 3
   menu :parent => "Miscellaneous"
   config.batch_actions = false
   config.per_page = [30, 50, 100, 250]

   # strong paramters handling
   permit_params :first_name, :last_name, :email, :academic_status_id,
   primary_address: [:address_1, :address_2, :city, :state, :post_code, :country, :phone],
   billable_address: [:first_name, :last_name, :address_1, :address_2, :city, :state, :post_code, :country, :phone]

   config.clear_action_items!
   action_item :new, only: :index do
      raw("<a href='/admin/customers/new'>New</a>") if current_user.admin?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if current_user.admin?
   end

   scope :all, :default => true
   scope :has_unpaid_invoices

   filter :last_name_or_first_name_starts_with, label: "Name"
   filter :email_starts_with, label: "Email"
   filter :agencies, :as => :select, collection: Agency.pluck(:name, :id)
   filter :academic_status, :as => :select, collection: AcademicStatus.pluck(:name, :id)

   index :as => :table do
      selectable_column
      column("Name", :sortable => false) do |customer|
         customer.full_name
      end
      column :requests do |customer|
         link_to customer.requests.to_a.size, admin_orders_path(:q => {:customer_id_eq => customer.id}, :scope => 'awaiting_approval')
      end
      column :orders do |customer|
         link_to customer.orders.count, admin_orders_path(:q => {:customer_id_eq => customer.id})
      end
      column :units do |customer|
         link_to customer.units.to_a.size, admin_units_path(:q => {:customer_id_eq => customer.id})
      end
      column :master_files do |customer|
         link_to customer.master_files_count.to_s, admin_master_files_path(:q => {:customer_id_eq => customer.id})
      end
      column :academic_status, :sortable => false
      column("Links") do |customer|
         div do
            link_to "Details", resource_path(customer), :class => "member_link view_link"
         end
         if current_user.admin?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(customer), :class => "member_link edit_link"
            end
         end
      end
   end

   show do
      div :class => 'three-column' do
         panel "Details", :id => 'customers' do
            attributes_table_for customer do
               row :full_name
               row :email do |customer|
                  format_email_in_sidebar(customer.email).gsub(/\s/, "")
               end
               row :academic_status
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
         f.input :academic_status, :as => :select
      end

      f.inputs "Primary Address (Required)", :class => 'inputs three-column' do
         f.semantic_fields_for :primary_address, customer.primary_address do |p|
            p.inputs do
               p.input :address_1
               p.input :address_2
               p.input :city
               p.input :state
               p.input :country, as: :select, collection: ActionView::Helpers::FormOptionsHelper::COUNTRIES, :input_html => {:class => 'chosen-select',  :style => 'width: 225px'}
               p.input :post_code
               p.input :phone
            end
         end
      end

      f.inputs "Billable Address (Optional)", :class => 'inputs three-column' do
         f.semantic_fields_for :billable_address, customer.billable_address do |b|
            b.inputs do
               b.input :first_name
               b.input :last_name
               b.input :address_1
               b.input :address_2
               b.input :city
               b.input :state
               b.input :country, as: :select, collection: ActionView::Helpers::FormOptionsHelper::COUNTRIES, :input_html => {:class => 'chosen-select',  :style => 'width: 225px'}
               b.input :post_code
               b.input :phone
            end
         end
      end

      f.inputs :class => 'columns-none customer-edit-actions' do
         f.actions
      end
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for customer do
         row :requests do |customer|
            link_to customer.requests.count, admin_orders_path(:q => {:customer_id_eq => customer.id}, :scope => 'awaiting_approval')
         end
         row :orders do |customer|
            link_to customer.orders_count.to_s, admin_orders_path(:q => {:customer_id_eq => customer.id})
         end
         row :units do |customer|
            link_to customer.units.count, admin_units_path(:q => {:customer_id_eq => customer.id})
         end
         row :master_files do |customer|
            link_to customer.master_files_count.to_s, admin_master_files_path(:q => {:customer_id_eq => customer.id})
         end
         row "On Behalf of Agencies" do |customer|
            raw(customer.agency_links)
         end
         row :date_of_first_order do |customer|
            format_date(customer.date_of_first_order)
         end
      end
   end

   controller do
      def create
         Customer.transaction do
            ca = params[:customer]
            @customer = Customer.create!(first_name: ca[:first_name],
               last_name: ca[:last_name], email: ca[:email],
               academic_status_id: ca[:academic_status_id])
            addr = params[:customer][:primary_address]
            Address.create!(addressable: @customer, address_type: "primary",
               address_1: addr[:address_1], address_2: addr[:address_s],
               city: addr[:city], state: addr[:state], post_code: addr[:post_code],
               country: addr[:country], phone: addr[:phone] )

            addr = params[:customer][:billable_address]
            if !addr.nil?
               if addr[:first_name].blank? && addr[:last_name].blank? && addr[:address_1].blank?
                  params[:customer].delete :billable_address
               end
            else
               Address.create!(addressable: @customer, address_type: "billable_address",
                  first_name: addr[:first_name],last_name: addr[:last_name],
                  address_1: addr[:address_1], address_2: addr[:address_2],
                  city: addr[:city], state: addr[:state], post_code: addr[:post_code],
                  country: addr[:country], phone: addr[:phone] )
            end
         end
         flash[:sucess] = "Customer #{@customer.full_name} created"
         redirect_to "/admin/customers/#{@customer.id}"
      rescue Exception => exception
         flash[:error] = "Customer create failed. Missing required fields."
         redirect_to "/admin/customers/new"
      end

      def update
         Customer.transaction do
            @customer = Customer.find(params[:id])
            ca = params[:customer]
            @customer.update(first_name: ca[:first_name], last_name: ca[:last_name],
               academic_status_id: ca[:academic_status_id], email:  ca[:email])

            addr = params[:customer][:primary_address]
            if !@customer.primary_address.nil?
               @customer.primary_address.update( address_1: addr[:address_1], address_2: addr[:address_s],
                  city: addr[:city], state: addr[:state], post_code: addr[:post_code],
                  country: addr[:country], phone: addr[:phone] )
            else
               Address.create!(addressable: @customer, address_type: "primary",
                  address_1: addr[:address_1], address_2: addr[:address_s],
                  city: addr[:city], state: addr[:state], post_code: addr[:post_code],
                  country: addr[:country], phone: addr[:phone] )
            end

            addr = params[:customer][:billable_address]
            all_blank = true
            addr.each do |key,val|
               if !val.blank?
                  all_blank = false
                  break
               end
            end
            if all_blank == false
               if !@customer.billable_address.nil?
                  @customer.billable_address.update(
                     first_name: addr[:first_name],last_name: addr[:last_name],
                     address_1: addr[:address_1], address_2: addr[:address_2],
                     city: addr[:city], state: addr[:state], post_code: addr[:post_code],
                     country: addr[:country], phone: addr[:phone] )
               else
                  Address.create!(addressable: @customer, address_type: "billable_address",
                     first_name: addr[:first_name],last_name: addr[:last_name],
                     address_1: addr[:address_1], address_2: addr[:address_2],
                     city: addr[:city], state: addr[:state], post_code: addr[:post_code],
                     country: addr[:country], phone: addr[:phone] )
               end
            end
         end
         flash[:sucess] = "Customer #{@customer.full_name} updated"
         redirect_to "/admin/customers/#{@customer.id}"
      end
   end
end
