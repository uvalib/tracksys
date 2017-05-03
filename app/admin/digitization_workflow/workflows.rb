ActiveAdmin.register Workflow do
   menu :parent => "Digitization Workflow", :priority => 2, if: proc{ !current_user.viewer? }

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
     div do
        panel "Workflow Name: #{workflow.name}" do
           div class: "workflow-description" do
             h4 do workflow.description end
          end
           render partial: "workflow_steps", locals: { workflow: workflow}
        end
     end
   end

   # EDIT page ================================================================
   #
   form :partial => "edit"

end
