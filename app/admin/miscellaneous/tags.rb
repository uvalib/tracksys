ActiveAdmin.register Tag do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }

   config.clear_action_items!
   config.batch_actions = false

   config.per_page = [30, 50, 100, 250]

   filter :tag_contains, label: "tag"

   index do
      column :tag
      column("Usage") do |tag|
         #/admin/master_files?utf8=✓&q%5Btags_id_equals%5D=5t&commit=Filter&order=filename_asc
         cnt= tag.master_files.count
         if cnt == 0
            "0"
         else
            url = "/admin/master_files?q%5Btags_id_equals%5D=#{tag.id}&commit=Filter&order=filename_asc"
            link_to "#{cnt}", url, :class => "member_link edit_link"
         end
      end
      column("Actions") do |tag|
        if current_user.admin?
           div do
             link_to "Edit", edit_resource_path(tag), :class => "member_link edit_link"
           end
           div do
             link_to "Delete", resource_path(tag), data:
               {:confirm => "Are you sure you want to delete this tag?"}, :method => :delete
           end
        end
      end
   end
end
