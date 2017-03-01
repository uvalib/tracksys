ActiveAdmin.register CollectionFacet do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }
   
   # strong paramters handling
   permit_params :name

   config.batch_actions = false
   config.filters = false

   config.sort_order = 'name_asc'
   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/collection_facets/new'>New</a>") if current_user.admin?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if current_user.admin?
   end

   index do
      column :name
      column("Links") do |use_right|
         if current_user.admin?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(use_right), :class => "member_link edit_link"}
         end
      end
   end
end
