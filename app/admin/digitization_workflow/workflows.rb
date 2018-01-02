ActiveAdmin.register Workflow do
   menu :parent => "Digitization Workflow", :priority => 2, if: proc{ !current_user.viewer? }

   # strong paramters handling
   permit_params :name, :description

   config.batch_actions = false
   config.filters = false
   config.sort_order = 'id_asc'
   config.clear_action_items!

   scope :active, :default => true
   scope :inactive

   # INDEX page ===============================================================
   #
   index do
      column :name
      column :description
      column("Number of Steps") do |workflow|
        workflow.num_steps
      end
      column("") do |workflow|
         div do
           link_to "Details", resource_path(workflow), :class => "member_link view_link"
         end
         if current_user.admin? && workflow.active
            div do
               link_to "Deactivate", deactivate_admin_workflow_path(workflow), :class => "member_link edit_link", :method => :post
            end
         end
         if current_user.admin? && workflow.active == false
            div do
               link_to "Activate", activate_admin_workflow_path(workflow), :class => "member_link edit_link", :method => :post
            end
         end
      end
   end

   # DETAILS page =============================================================
   #
   show do
     div do
        panel "Workflow Name: #{workflow.name}" do
           div class: "workflow-description" do
             h4 do
                workflow.description
             end
             h5 do
                "Base Directory: #{workflow.base_directory}"
             end
          end
           render partial: "/admin/digitization_workflow/workflows/workflow_steps", locals: { workflow: workflow}
        end
     end
   end

   member_action :activate, :method => :post do
      workflow = Workflow.find(params[:id])
      workflow.update(active: true)
      redirect_to "/admin/workflows", :notice => "Workflow '#{workflow.name}' has been activated."
   end
   member_action :deactivate, :method => :post do
      workflow = Workflow.find(params[:id])
      workflow.update(active: false)
      redirect_to "/admin/workflows", :notice => "Workflow '#{workflow.name}' has been deactivated."
   end

end
