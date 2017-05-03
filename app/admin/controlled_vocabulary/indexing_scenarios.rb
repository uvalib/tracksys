ActiveAdmin.register IndexingScenario do
   # strong paramters handling
   permit_params :name, :pid, :datastream_name, :repository_url

   config.sort_order = 'name_asc'
   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/indexing_scenarios/new'>New</a>") if current_user.admin?
   end

   menu :parent => "Controlled Vocabulary", if: proc{ current_user.admin? || current_user.supervisor? }

   config.batch_actions = false
   config.filters = false

   index do
      column :name
      column("Metadata Records") do |indexing_scenario|
        indexing_scenario.metadata_count
      end
      column("Links") do |indexing_scenario|
         if current_user.admin?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(indexing_scenario), :class => "member_link edit_link"}
         end
      end
   end

   form do |f|
      f.inputs :class => 'columns-none' do
         f.input :name
      end

      f.inputs :class => 'columns-none' do
         f.actions
      end
   end
end
