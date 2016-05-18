ActiveAdmin.register IndexDestination do

   # strong paramters handling
   permit_params :nickname, :hostname, :port, :protocol, :context

   config.sort_order = 'nickname_asc'
   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/index_destinations/new'>New</a>") if !current_user.viewer?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer?
   end

   menu :parent => "Miscellaneous"

   config.batch_actions = false
   config.filters = false

   index do
      div :class => 'two-column' do
         panel "NOTE" do
            h3 "Index Destinations only control a flag generated and inserted in Solr records."
            h3 "They will always get posted to #{STAGING_SOLR_URL}, and then pulled by Bob H. on request."
         end
      end
      div :class => 'two-column' do
        panel "Config Environment Info" do
           dl do
             dt "Rails.env="
             dd Rails.env
             dt "SOLR_PRODUCTION_SERVER="
             dd link_to  SOLR_PRODUCTION_NAME, 'http://' + SOLR_PRODUCTION_NAME + '/admin' , :target => "_blank"
             dt "STAGING_SOLR_URL="
             dd link_to STAGING_SOLR_URL, STAGING_SOLR_URL + '/admin/' , :target => "_blank"
             dt "FEDORA_REST_URL="
             dd link_to FEDORA_REST_URL, FEDORA_REST_URL , :target => "_blank"
             dt "FEDORA_PROXY_URL="
             dd link_to FEDORA_PROXY_URL, FEDORA_PROXY_URL , :target => "_blank"
          end
        end
     end
      column :nickname
      column :hostname
      column :port
      column :context
      column :url do |i|
         link_to "#{i.url}/admin/", "#{i.url}/admin/", :target => "_blank"
      end
      column :created_at
      column :updated_at
      column("Bibls") do |index_destination|
         link_to index_destination.bibls.size, admin_bibls_path(:q => {:index_destination_id_eq => index_destination.id})
      end
      column("Components") do |index_destination|
         link_to index_destination.components.size, admin_components_path(:q => {:index_destination_id_eq => index_destination.id})
      end
      column("Master Files") do |index_destination|
         link_to index_destination.master_files.size, admin_master_files_path(:q => {:index_destination_id_eq => index_destination.id})
      end
      column("Units") do |index_destination|
         link_to index_destination.units.size, admin_units_path(:q => {:index_destination_id_eq => index_destination.id})
      end
      column("Links") do |index_destination|
         div do
            link_to "Details", resource_path(index_destination), :class => "member_link view_link"
         end
         if !current_user.viewer?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(index_destination), :class => "member_link edit_link"
            end
         end
      end
   end

   show do
      panel "General Information" do
         attributes_table_for index_destination do
            row :name
            row :hostname
            row :port
            row :context
            row :url do |i|
               link_to "#{i.url}", i.url, :target => "_blank"
            end
            row :created_at
            row :updated_at
         end
      end
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for index_destination do
         row("Units") do |index_destination|
            link_to index_destination.units.size, admin_units_path(:q => {:index_destination_id_eq => index_destination.id})
         end
         row("Master Files") do |index_destination|
            link_to index_destination.master_files.size, admin_master_files_path(:q => {:index_destination_id_eq => index_destination.id})
         end
         row("Bibls") do |index_destination|
            link_to index_destination.bibls.size, admin_bibls_path(:q => {:index_destination_id_eq => index_destination.id})
         end
         row("Components") do |index_destination|
            link_to index_destination.components.size, admin_components_path(:q => {:index_destination_id_eq => index_destination.id})
         end
      end
   end
end
