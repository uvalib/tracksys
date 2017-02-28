ActiveAdmin.register_page "Staff Skills" do
   menu :parent => "Digitization Workflow", :priority => 3

   content do
      render partial: 'skills_matrix'
   end
end
