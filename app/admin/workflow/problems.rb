ActiveAdmin.register Problem do
   menu :parent => "Digitization Workflow", if: proc{ current_user.admin? || current_user.supervisor? }

   # strong paramters handling
   permit_params :name

   config.batch_actions = false
   config.filters = false

   config.sort_order = 'id_asc'
   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/use_rights/new'>New</a>") if current_user.admin?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if current_user.admin?
   end

   index do
      column :id
      column :name
      column("Times Reported") do |problem|
         problem.notes_count
      end
      column("Links") do |problem|
         if current_user.admin?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(problem), :class => "member_link edit_link"}
         end
      end
   end
end