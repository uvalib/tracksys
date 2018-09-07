ActiveAdmin.register ExternalSystem do
   menu :parent => "Controlled Vocabulary", if: proc{ current_user.admin? || current_user.supervisor? }
   config.sort_order = "id_asc"

   # strong paramters handling
   permit_params :name, :public_url, :api_url

   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/external_systems/new'>New</a>") if current_user.admin?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if current_user.admin?
   end

   config.batch_actions = false
   config.filters = false

   index do
      column :id
      column :name
      column :public_url
      column :api_url
      column("Links") do |es|
         if current_user.admin?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(es), :class => "member_link edit_link"}
         end
      end
   end


end
