ActiveAdmin.register Task do
   menu :priority => 2

   config.batch_actions = false

   scope :all, :default => true
   scope :unassigned

   filter :workflow, :as => :select, :collection => Workflow.all
   filter :owner_computing_id, :as => :select, :label => "Owner", :collection => StaffMember.all
   filter :category, :as => :select, :collection => Task.categories
   filter :unit_id, :as => :numeric, :label => "Unit ID"
   filter :due_on
   filter :added_at
   filter :finished_at

   # INDEX page ===============================================================
   #
   index do
      column :id
      column ("Project"), :sortable => :project_name do |task|
         raw("<a href='/admin/orders/#{task.order.id}'>#{task.project_name}</a>")
      end
      column :unit
      column :customer
      column :priority
      column("Due", :sortable => :due_on) do |task|
        format_date(task.due_on)
      end
      column("Progress", class:"status-col") do |task|
         render :partial=>"status", :locals=>{ task: task}
      end
      column("Owner") do |task|
         if task.owner.nil?
            "Unassigned"
         else
            owner = task.owner
            raw("<a href='/admin/staff_members/#{owner.id}'>#{owner.full_name} (#{owner.computing_id})</a>")
         end
      end
      column("Actions") do |task|
         div do
           link_to "Details", resource_path(task), :class => "member_link view_link"
         end
         if task.owner.nil?
            div do
              link_to "Claim", "/admin/tasks/#{task.id}/claim",
                  data: {:confirm => "Claim this task?"}, :method => :put
            end
         end
         if current_user.admin? || current_user.supervisor
            div do
              raw("<p class='assign-link'>Assign</p>")
            end
         end
      end
   end

   # MEMBER ACTIONS  ==========================================================
   #
   member_action :claim, :method => :put do
      task = Task.find(params[:id])
      assignment = Assignment.new(task: task, staff_member: current_user, step: task.next_step)
      if assignment.save
         task.update(owner: current_user)
         redirect_to "/admin/tasks", :notice => "You have claimed task #{task.id}"
      else
         redirect_to "/admin/tasks", :notice => "Unable to claim task #{task.id}"
      end
   end
end
