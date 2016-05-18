ActiveAdmin.register IndexingScenario do
   # strong paramters handling
   permit_params :name, :pid, :datastream_name, :repository_url

   config.sort_order = 'name_asc'
   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/indexing_scenarios/new'>New</a>") if !current_user.viewer?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer?
   end

   menu :parent => "Miscellaneous"

   config.batch_actions = false
   config.filters = false

   index do
      column :name
      column :pid
      column :datastream_name
      column :repository_url
      column("Bibls") do |indexing_scenario|
         link_to indexing_scenario.bibls.count, admin_bibls_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end
      column("Components") do |indexing_scenario|
         link_to indexing_scenario.components.count, admin_components_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end
      column("Master Files") do |indexing_scenario|
         link_to indexing_scenario.master_files.count, admin_master_files_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end
      column("Units") do |indexing_scenario|
         link_to indexing_scenario.units.count, admin_units_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
      end
      column("Links") do |indexing_scenario|
         div {link_to "Details", resource_path(indexing_scenario), :class => "member_link view_link"}
         if !current_user.viewer?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(indexing_scenario), :class => "member_link edit_link"}
         end
      end
   end

   show do
      panel "General Information" do
         attributes_table_for indexing_scenario do
            row :name
            row :pid
            row :datastream_name
            row :repository_url
            row :created_at
            row :updated_at
         end
      end


      div :class => 'admin-information' do
         h4 "Note that although the stylesheets are stored in the Tracksys app directory tree, within Tracksys they are accessed from Fedora. Any changes to the stylesheets have to be uploaded to Fedora Repo for those changes to take effect."
      end

      panel "Repository Link" do
         link_to indexing_scenario.complete_url, indexing_scenario.complete_url, :target => "_blank"
      end
      panel "Fedora Admin Link" do
         link_to  indexing_scenario.repository_url + '/fedora/admin' , indexing_scenario.repository_url + '/fedora/admin', :target => "_blank"
      end
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for indexing_scenario do
         row("Units") do |indexing_scenario|
            link_to indexing_scenario.units.count, admin_units_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
         end
         row("Master Files") do |indexing_scenario|
            link_to indexing_scenario.master_files.count, admin_master_files_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
         end
         row("Bibls") do |indexing_scenario|
            link_to indexing_scenario.bibls.count, admin_bibls_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
         end
         row("Components") do |indexing_scenario|
            link_to indexing_scenario.components.count, admin_components_path(:q => {:indexing_scenario_id_eq => indexing_scenario.id})
         end
      end
   end

end
