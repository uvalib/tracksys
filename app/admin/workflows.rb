ActiveAdmin.register Workflow do
   menu :parent => "Digitization Workflow", :priority => 2

   # strong paramters handling
   permit_params :name, :description

   config.batch_actions = false
   config.filters = false
   config.sort_order = 'id_asc'
   config.clear_action_items!

   # INDEX page ===============================================================
   #
   index do
      column :id
      column :name
      column :description
      column("Number of Steps") do |workflow|
        workflow.num_steps
      end
      column("") do |workflow|
         div do
           link_to "Details", resource_path(workflow), :class => "member_link view_link"
         end
         # if current_user.admin?
         #    div {link_to I18n.t('active_admin.edit'), edit_resource_path(workflow), :class => "member_link edit_link"}
         # end
      end
   end

   # DETAILS page =============================================================
   #
   show do
     div :class => 'one-third' do
        panel "General Information" do
          attributes_table_for workflow do
            row :name
            row :description
          end
        end
     end
     div :class => 'two-thirds' do
        panel "Workflow Steps" do
           render partial: "workflow_steps", locals: { workflow: workflow}
        end
     end
   end

   # EDIT page ================================================================
   #
   form :partial => "edit"

end
