ActiveAdmin.register Task do
   menu :priority => 2

   config.batch_actions = false
   config.clear_action_items!

   scope :all, :default => true
   scope :unassigned
   scope :overdue

   filter :workflow, :as => :select, :collection => Workflow.all
   filter :owner_computing_id, :as => :select, :label => "Owner", :collection => StaffMember.all
   filter :item_type, :as => :select, :collection => Task.item_types
   filter :priority, :as => :select, :collection => Task.priorities
   filter :unit_id, :as => :numeric, :label => "Unit ID"
   filter :due_on
   filter :added_at
   filter :finished_at

   # INDEX page ===============================================================
   #
   index :download_links => false do
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

   # DETAILS page ===============================================================
   #
   show :title => proc {|invoice| "Task ##{invoice.id}"} do
      render "details", :context => self
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for task do
         row "Metadata" do |task|
            if !task.unit.metadata.nil?
               disp = "<a href='/admin/#{task.unit.metadata.url_fragment}/#{task.unit.metadata.id}'><span>#{task.unit.metadata.pid}<br/>#{task.unit.metadata.title}</span></a>"
               raw( disp)
            end
         end
         row :unit do |task|
            link_to "##{task.unit.id}", admin_unit_path(task.unit.id)
         end
         row :order do |task|
            link_to "##{task.order.id}", admin_order_path(task.order.id)
         end
      end
   end

   sidebar "Progress", :only => [:show]  do
      attributes_table_for task do
         row :workflow
         row("Current Step") do |task|
            if task.finished_at
               "Finished"
            else
               task.current_step.name
            end
         end
         row :owner
         row ("Assigned") do |task|
            format_datetime(task.active_assignment.assigned_at) if !task.owner.nil?
         end
         row ("Started") do |task|
            format_datetime(task.active_assignment.started_at) if !task.owner.nil?
         end
      end
   end

   sidebar "Assignment Workflow", :only => [:show],if: proc{ current_user == task.owner}  do
      div :class => 'workflow_button' do
         options = {:method => :put}
         options[:disabled] = true if task.active_assignment.started?
         button_to "Start Assignment", start_work_admin_task_path(),options
      end
      if task.current_step.fail_step.nil?
         div :class => 'workflow_button' do
            options = {:method => :put}
            options[:disabled] = true if !task.active_assignment.started?
            button_to "Finish Assignment", finish_work_admin_task_path(),options
         end
      else

      end
   end

   # MEMBER ACTIONS  ==========================================================
   #
   member_action :start_work, :method => :put do
      task = Task.find(params[:id])
      task.update(started_at: Time.now)
      task.active_assignment.update(started_at: Time.now)
      logger.info("User #{current_user.computing_id} starting workflow [#{task.workflow.name}] step [#{task.current_step.name}]")
      redirect_to "/admin/tasks/#{params[:id]}", :notice => "Workflow step #{task.current_step.name} has been started"
   end

   member_action :finish_work, :method => :put do
      task = Task.find(params[:id])
      logger.info("User #{current_user.computing_id} finished workflow [#{task.workflow.name}] step [#{task.current_step.name}]")
      finished_step = task.current_step

      # First, move any files to thier destination if needed
      # TODO move and handle any MD5 checksum errors. Don't finish if fail?

      # Mark assignment/task complete
      if task.finish_assignment
         redirect_to "/admin/tasks/#{params[:id]}", :notice => "Workflow step #{finished_step.name} has been finished"
      else
         redirect_to "/admin/tasks/#{params[:id]}", :notice => "Workflow step #{finished_step.name} error finishing step"
      end
   end

   member_action :settings, :method => :put do
      task = Task.find(params[:id])
      if params[:camera]
         ok = task.update(camera: params[:camera], lens: params[:lens], resolution: params[:resolution])
      else
         ok = task.update(item_condition: params[:condition].to_i)
      end
      if ok
         render nothing:true
      else
         render text: task.errors.full_messages.to_sentence, status: :error
      end
   end

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
