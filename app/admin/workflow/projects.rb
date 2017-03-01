ActiveAdmin.register Project do
   menu :parent => "Digitization Workflow", :priority => 1
   config.per_page = 10
   config.sort_order = "due_on_asc"

   config.batch_actions = false
   config.clear_action_items!

   scope :active, :default => true
   scope("Assigned to me") { |project| Project.active.where(owner: current_user) }
   scope :bound, if: proc { current_user.can_process? Category.find(1)}
   scope :flat, if: proc { current_user.can_process? Category.find(2) }
   scope :film, if: proc { current_user.can_process? Category.find(3) }
   scope :oversize, if: proc { current_user.can_process? Category.find(4) }
   scope :special, if: proc { current_user.can_process? Category.find(5) }
   scope :unassigned
   scope :overdue
   scope :all

   filter :workflow, :as => :select, :collection => Workflow.all
   filter :owner_computing_id, :as => :select, :label => "Owner", :collection => StaffMember.all
   filter :priority, :as => :select, :collection => Project.priorities
   filter :order_id, :as => :numeric, :label => "Order ID"
   filter :unit_id, :as => :numeric, :label => "Unit ID"
   filter :due_on
   filter :added_at


   # INDEX page ===============================================================
   #
   index  as: :grid, :download_links => false, columns: 2 do |project|
      @first = true if @first.nil?
      render partial: 'card', locals: {project: project, first: @first }
      @first = false
   end

   # DETAILS page ===============================================================
   #
   show :title => proc {|project| "Project ##{project.id}"} do
      render "details", :context => self
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for project do
         row "Metadata" do |project|
            if !project.unit.metadata.nil?
               disp = "<a href='/admin/#{project.unit.metadata.url_fragment}/#{project.unit.metadata.id}'><span>#{project.unit.metadata.pid}<br/>#{project.unit.metadata.title}</span></a>"
               raw( disp)
            end
         end
         row :unit do |project|
            link_to "##{project.unit.id}", admin_unit_path(project.unit.id)
         end
         row :order do |project|
            link_to "##{project.order.id}", admin_order_path(project.order.id)
         end
      end
   end

   sidebar "Progress", :only => [:show]  do
      attributes_table_for project do
         row :workflow
         row("Current Step") do |project|
            if project.finished_at
               "Finished"
            else
               project.current_step.name
            end
         end
         if !project.finished?
            row :owner
            row ("Assigned") do |project|
               format_datetime(project.active_assignment.assigned_at) if !project.owner.nil?
            end
            row ("Started") do |project|
               format_datetime(project.active_assignment.started_at) if !project.owner.nil?
            end
            row ("Working Directory") do |project|
               project.current_step.start_dir
            end
         end
      end
   end

   sidebar "Assignment Workflow", :only => [:show], if: proc{ !project.finished? } do
      if current_user == project.owner
         div :class => 'workflow_button project' do
            clazz = "admin-button"
            clazz << " disabled locked" if project.active_assignment.started? || project.active_assignment.error?
            raw("<span class='#{clazz}' id='start-assignment-btn'>Start</span>")
         end
         div :class => 'workflow_button project' do
            clazz = "admin-button"
            clazz << " disabled locked" if !project.active_assignment.started? && !project.active_assignment.error? || project.workstation.nil?
            raw("<span class='#{clazz}' id='finish-assignment-btn'>Finish</span>")
         end
         if project.workstation.nil?
            div class: 'equipment-note' do "Assignment cannot be finished until the workstation has been set." end
         end
         if !project.current_step.fail_step.nil?
            div :class => 'workflow_button project' do
               c = "admin-button reject"
               c << " disabled locked" if !project.active_assignment.started?
               raw("<span id='reject-button' class='#{c}'>Reject</span>")
            end
         end
      else
         div :class => 'workflow_button project' do
            options = {:method => :put}
            options[:disabled] = true if !project.claimable_by? current_user
            button_to "Claim", "/admin/projects/#{project.id}/claim?details=1", options
         end
         if current_user.admin? || current_user.supervisor?
            div class: 'workflow_button project' do
               options = {method: :put, disabled: true}
               button_to "Assign", "", options
            end
         end
      end
   end

   # MEMBER ACTIONS  ==========================================================
   #
   member_action :start_assignment, :method => :put do
      project = Project.find(params[:id])
      project.start_work
      logger.info("User #{current_user.computing_id} starting workflow [#{project.workflow.name}] step [#{project.current_step.name}]")
      render nothing: true
   end

   member_action :reject_assignment, :method => :put do
      project = Project.find(params[:id])
      logger.info("User #{current_user.computing_id} REJECTS workflow [#{project.workflow.name}] step [#{project.current_step.name}]")
      project.reject(params[:duration])
      render nothing: true
   end

   member_action :finish_assignment, :method => :post do
      project = Project.find(params[:id])
      logger.info("User #{current_user.computing_id} finished workflow [#{project.workflow.name}] step [#{project.current_step.name}]")
      project.finish_assignment(params[:duration])
      render nothing: true
   end

   member_action :note, :method => :post do
      project = Project.find(params[:id])
      type = params[:note_type].to_i
      prob_id = params[:problem]
      prob = nil
      if Note.note_types[:problem] == type
         prob = Problem.find(prob_id)
      end
      begin
        note = Note.create!(staff_member: current_user, project: project, note_type: type, note: params[:note], problem: prob )
        html = render_to_string partial: "note", locals: {note: note}
        render json: {html: html}
     rescue Exception => e
        Rails.logger.error e.to_s
        render text: "Create note FAILED: #{e.to_s}", status:  :error
     end
   end

   member_action :settings, :method => :put do
      project = Project.find(params[:id])
      if params[:camera]
         ws = Workstation.find(params[:workstation])
         project.equipment.clear
         ws.equipment.each do |e|
            project.equipment << e
         end
         ok = project.update(
            workstation:ws, capture_resolution: params[:capture_resolution],
            resized_resolution: params[:resized_resolution], resolution_note: params[:resolution_note])
         if !ok
            render text: project.errors.full_messages.to_sentence, status: :error
         else
            html = render_to_string partial: "project_equipment", locals: {equipment: project.equipment}
            render json: {html: html}, status: :ok
         end
      else
         if project.update(item_condition: params[:condition].to_i, viu_number: params[:viu_number])
            render nothing:true
         else
            render text: project.errors.full_messages.to_sentence, status: :error
         end
      end
   end

   member_action :claim, :method => :put do
      url = "/admin/projects"
      url = "/admin/projects/#{params[:id]}" if !params[:details].nil?
      project = Project.find(params[:id])
      assignment = Assignment.new(project: project, staff_member: current_user, step: project.current_step)
      if assignment.save
         project.update(owner: current_user)
         redirect_to url, :notice => "You have claimed project #{project.id}"
      else
         logger.error("Claim project failed: #{assignment.errors.full_messages.to_sentence}")
         redirect_to url, :notice => "Unable to claim project #{project.id}"
      end
   end

   controller do
      def scoped_collection
         if !current_user.admin? && !current_user.supervisor?
            ids = []
            current_user.skills.each do |s|
               ids << s.id
            end
            # Students/editors only see projects that match their skills
            end_of_association_chain = Project.where("category_id in (#{ids.join(',')})")
         else
            # Admin and supervisor see all projects
            end_of_association_chain = Project.all.order(due_on: :asc)
         end
      end
  end
end
