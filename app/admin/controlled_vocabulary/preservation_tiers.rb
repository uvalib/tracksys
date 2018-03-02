ActiveAdmin.register PreservationTier do
   menu :parent => "Controlled Vocabulary", if: proc{ current_user.admin? || current_user.supervisor? }

   # strong paramters handling
   permit_params :name, :description

   config.batch_actions = false
   config.filters = false

   config.sort_order = 'id_asc'
   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/preservation_tiers/new'>New</a>") if current_user.admin?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if current_user.admin?
   end

   index do
      column :id
      column :name
      column :description
      column("Links") do |tier|
         if current_user.admin?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(tier), :class => "member_link edit_link"}
         end
      end
   end
end
