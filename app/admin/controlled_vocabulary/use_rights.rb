ActiveAdmin.register UseRight do
   # strong paramters handling
   permit_params :name, :uri, :statement, :commercial_use, :educational_use, :modifications

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

   menu :parent => "Controlled Vocabulary", if: proc{ current_user.admin? || current_user.supervisor? }

   index do
      column :id
      column :name
      column :uri
      column("Metadata Records") do |use_right|
        use_right.metadata_count
      end
      column("Master Files") do |use_right|
         use_right.master_files.size()
      end
      column("Links") do |use_right|
         div do
           link_to "Details", resource_path(use_right), :class => "member_link view_link"
         end
         if current_user.admin?
            div {link_to I18n.t('active_admin.edit'), edit_resource_path(use_right), :class => "member_link edit_link"}
         end
      end
   end

   show :title => proc { |use_right| use_right.name } do
     panel "Detailed Information" do
       attributes_table_for use_right do
         row :name
         row :uri
         row :statement do |use_right|
            raw("<pre>#{use_right.statement}</pre>")
         end
         row ("Permitted Uses") do |use_right|
            use_right.uses
         end
       end
     end
   end
end
