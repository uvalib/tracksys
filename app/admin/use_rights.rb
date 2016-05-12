ActiveAdmin.register UseRight do
   # strong paramters handling
   permit_params :name

   config.batch_actions = false
   config.filters = false

   config.sort_order = 'id_asc'
   config.clear_action_items!
   action_item :new, :only => :index do
      raw("<a href='/admin/use_rights/new'>New</a>") if !current_user.viewer?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer?
   end

   menu :parent => "Miscellaneous"

   index do
      column :name
      column("Bibls") do |use_right|
         link_to use_right.bibls.count, admin_bibls_path(:q => {:use_right_id_eq => use_right.id})
      end
      column("Master Files") do |use_right|
         link_to use_right.master_files.count, admin_master_files_path(:q => {:use_right_id_eq => use_right.id})
      end
      column("Links") do |use_right|
         if !current_user.viewer?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(use_right), :class => "member_link edit_link"}
         end
      end
   end
end
