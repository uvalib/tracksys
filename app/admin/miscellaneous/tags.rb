ActiveAdmin.register_page "Tags" do
   menu :parent => "Miscellaneous", if: proc{ current_user.admin? || current_user.supervisor? }

   content do
   end
end
