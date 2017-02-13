ActiveAdmin.register Task do
   menu :priority => 2
   config.per_page = 10
   config.sort_order = "due_on_asc"

   config.batch_actions = false
   config.clear_action_items!

   scope :active, :default => true
   scope :unassigned
   scope :overdue
   scope :all

   filter :workflow, :as => :select, :collection => Workflow.all
   filter :owner_computing_id, :as => :select, :label => "Owner", :collection => StaffMember.all
   filter :item_type, :as => :select, :collection => Task.item_types, label:"Category"
   filter :priority, :as => :select, :collection => Task.priorities
   filter :order_id, :as => :numeric, :label => "Order ID"
   filter :unit_id, :as => :numeric, :label => "Unit ID"
   filter :due_on
   filter :added_at


   # INDEX page ===============================================================
   #
   index  as: :grid, :download_links => false, columns: 2 do |task|
      @first = true if @first.nil?
      render partial: 'card', locals: {task: task, first: @first }
      @first = false
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
         row ("Working Directory") do |task|
            task.current_step.start_dir
         end
      end
   end

   sidebar "Assignment Workflow", :only => [:show] do
      if current_user == task.owner
         div :class => 'workflow_button task' do
            options = {:method => :put}
            options[:disabled] = true if task.active_assignment.started? || task.active_assignment.error?
            button_to "Start", start_assignment_admin_task_path(),options
         end
         div :class => 'workflow_button task' do
            options = {:method => :put}
            options[:disabled] = true if !task.active_assignment.started? && !task.active_assignment.error?
            button_to "Finish", finish_assignment_admin_task_path(),options
         end
         if !task.current_step.fail_step.nil?
            c = "reject"
            c << " disabled" if !task.active_assignment.started?
            raw("<div class='workflow_button task' id='reject-button'><input type='submit' class='#{c}' value='Reject'/></div>")
         end
      else
         div :class => 'workflow_button task' do
            options = {:method => :put}
            button_to "Claim Task", "/admin/tasks/#{task.id}/claim?details=1", options
         end
         if current_user.admin? || current_user.supervisor?
            div class: 'workflow_button task' do
               options = {method: :put, disabled: true}
               button_to "Assign Task", "", options
            end
         end
      end
   end

   # MEMBER ACTIONS  ==========================================================
   #
   member_action :start_assignment, :method => :put do
      task = Task.find(params[:id])
      task.start_work
      logger.info("User #{current_user.computing_id} starting workflow [#{task.workflow.name}] step [#{task.current_step.name}]")
      redirect_to "/admin/tasks/#{params[:id]}"
   end

   member_action :reject_assignment, :method => :put do
      task = Task.find(params[:id])
      logger.info("User #{current_user.computing_id} REJECTS workflow [#{task.workflow.name}] step [#{task.current_step.name}]")
      task.reject
      render text: "ok"
   end

   member_action :finish_assignment, :method => :put do
      task = Task.find(params[:id])
      logger.info("User #{current_user.computing_id} finished workflow [#{task.workflow.name}] step [#{task.current_step.name}]")
      task.finish_assignment
      redirect_to "/admin/tasks/#{params[:id]}"
   end

   member_action :note, :method => :post do
      task = Task.find(params[:id])
      type = params[:note_type].to_i
      prob_id = params[:problem]
      prob = nil
      if Note.note_types[:problem] == type
         prob = Problem.find(prob_id)
      end
      begin
        note = Note.create!(staff_member: current_user, task: task, note_type: type, note: params[:note], problem: prob )
        html = render_to_string partial: "note", locals: {note: note}
        render json: {html: html}
     rescue Exception => e
        Rails.logger.error e.to_s
        render text: "Create note FAILED: #{e.to_s}", status:  :error
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
      url = "/admin/tasks"
      url = "/admin/tasks/#{params[:id]}" if !params[:details].nil?
      task = Task.find(params[:id])
      assignment = Assignment.new(task: task, staff_member: current_user, step: task.current_step)
      if assignment.save
         task.update(owner: current_user)
         redirect_to url, :notice => "You have claimed task #{task.id}"
      else
         logger.error("Claim task failed: #{assignment.errors.full_messages.to_sentence}")
         redirect_to url, :notice => "Unable to claim task #{task.id}"
      end
   end
end
