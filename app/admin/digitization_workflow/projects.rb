ActiveAdmin.register Project do
   menu :parent => "Digitization Workflow", :priority => 1, if: proc{ !current_user.viewer? }
   config.per_page = 10
   config.sort_order = ""

   config.batch_actions = false
   config.clear_action_items!

   scope ("Assigned to me"), default:lambda{ current_user.student? } do |project|
      Project.active.where(owner: current_user)
   end
   scope :active, :default => lambda{ current_user.admin? }
   scope :ready_to_finalize, if: proc { !current_user.student?}, :default => lambda{ current_user.supervisor? }

   scope :unassigned
   scope :overdue
   scope :failed_qa, if: proc { !current_user.student?}
   scope :has_error, if: proc { !current_user.student?}
   scope :bound, if: proc { current_user.can_process? Category.find(1)}
   scope :flat, if: proc { current_user.can_process? Category.find(2) }
   scope :film, if: proc { current_user.can_process? Category.find(3) }
   scope :oversize, if: proc { current_user.can_process? Category.find(4) }
   scope :special, if: proc { current_user.can_process? Category.find(5) }
   scope :medium_rare
   scope :patron
   scope :digital_collection_building
   scope :grant
   scope :finished, if: proc { !current_user.student?}

   filter :workflow, :as => :select, :collection => Workflow.all
   filter :owner_id, :as => :select, :label => "Assigned to", :collection => StaffMember.where(is_active:1).order(first_name: :asc)
   filter :by_assignee_in, :as => :select, :label => "Worked on by", :collection => StaffMember.where(is_active:1).order(first_name: :asc)
   filter :priority, :as => :select, :collection => Project.priorities
   filter :id_equals, :label => "Project ID"
   filter :order_id_equals, :label => "Order ID"
   filter :unit_id_equals, :label => "Unit ID"
   filter :metadata_call_number_starts_with, :as => :string, :label => "Call Number"
   filter :workstation, :as => :select
   filter :due_on
   filter :added_at

   action_item :delete, only: :show do
      link_to "Delete", "/admin/projects/#{resource.id}", method: :delete, data: {confirm: "Delete this project? All data will be lost. Contine?"} if current_user.admin?
   end


   # INDEX page ===============================================================
   #
   index  as: :grid, :download_links => false, columns: 2 do |project|
      @first = true if @first.nil?
      footer =  true
      footer = false if params[:scope] && params[:scope] == "finished"
      render partial: '/admin/digitization_workflow/projects/card', locals: {project: project, first: @first, footer: footer}
      @first = false
   end

   # DETAILS page ===============================================================
   #
   show :title => proc {|project| "Project ##{project.id}"} do
      render "/admin/digitization_workflow/projects/details", :context => self
   end

   sidebar "Related Information", :only => [:show] do
      attributes_table_for project do
         row "Metadata" do |project|
            if !project.unit.metadata.nil?
               disp = "<a href='/admin/#{project.unit.metadata.url_fragment}/#{project.unit.metadata.id}'>"
               disp << "<span>#{project.unit.metadata.pid}<br/>#{truncate_words(project.unit.metadata.title, 100)}</span></a>"
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
               raw("<b class='step'>#{project.current_step.name} :</b> #{project.current_step.description}")
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
               project.working_dir
            end
         end
      end
   end

   sidebar "Assignment Workflow", :only => [:show], if: proc{ !project.finished? } do
      render "/admin/digitization_workflow/projects/assignment_workflow", :context => self
   end

   # MEMBER ACTIONS  ==========================================================
   #
   member_action :start_assignment, :method => :put do
      project = Project.find(params[:id])
      project.start_assignment
      logger.info("User #{current_user.computing_id} starting workflow [#{project.workflow.name}] step [#{project.current_step.name}]")
      render plain: "OK"
   end

   member_action :reject_assignment, :method => :put do
      project = Project.find(params[:id])
      logger.info("User #{current_user.computing_id} REJECTS workflow [#{project.workflow.name}] step [#{project.current_step.name}]")
      project.reject(params[:duration])
      render plain: "OK"
   end

   member_action :finish_assignment, :method => :post do
      project = Project.find(params[:id])
      logger.info("User #{current_user.computing_id} finished workflow [#{project.workflow.name}] step [#{project.current_step.name}]")
      project.finish_assignment(params[:duration])
      render plain: "OK"
   end

   member_action :note, :method => :post do
      project = Project.find(params[:id])
      type = params[:note_type].to_i
      problems = params[:problems]
      if type == 2 && problems.nil? || (!problems.nil? && problems.length == 0)
         render plain: "At least one problem must be selected.", status:  :bad_request
         return
      end

      begin
         note = Note.create!(staff_member: current_user, project: project, note_type: type, note: params[:note], step: project.current_step )
         if !problems.nil?
            problems.each do |prob_id|
               prob = Problem.find(prob_id.to_i)
               note.problems << prob
            end
         end

         html = render_to_string partial: "/admin/digitization_workflow/projects/note", locals: {note: note}
         render json: {html: html}
      rescue Exception => e
         Rails.logger.error e.to_s
         render plain: "Create note FAILED: #{e.to_s}", status:  :internal_server_error
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
            render json: {status: "fail", enable_finish: false, error: project.errors.full_messages.to_sentence}, status: :bad_request
         else
            html = render_to_string partial: "/admin/digitization_workflow/projects/project_equipment", locals: {equipment: project.equipment}
            render json: {html: html, enable_finish: project.assignment_finish_available?}, status: :ok
         end
         return
      end

      if params[:container_type]
         project.update(container_type_id: params[:container_type] )
      end

      if params[:category]
         project.update(category_id: params[:category], item_condition: params[:item_condition].to_i,
                        condition_note: params[:condition_note], viu_number: params[:viu_number] )
      end

      if params[:viu_number]
         resp = project.update(viu_number: params[:viu_number] )
      end

      ocr_mf = params[:ocr_master_files] == "true"
      project.unit.update(ocr_master_files: ocr_mf)

      if params[:ocr_hint_id]
         logger.info "Setting OCR hint to #{params[:ocr_hint_id]}"
         ocr_resp = project.unit.metadata.update( ocr_hint_id: params[:ocr_hint_id] )
         if !ocr_resp
            logger.info "Unable to set OCR hint: #{project.unit.metadata.errors.full_messages.to_sentence}"
         end
      end

      if params[:ocr_language_hint]
         params[:ocr_language_hint].reject!(&:empty?)
            params[:ocr_language_hint] = params[:ocr_language_hint].join("+")
         project.unit.metadata.update( ocr_language_hint: params[:ocr_language_hint] )
      else
         project.unit.metadata.update( ocr_language_hint: "" )
      end

      render json: {status: "success", enable_finish: project.assignment_finish_available?}
   end

   member_action :unassign, :method => :post do
      if !(current_user.admin? || current_user.supervisor?)
         render plain: "You do not have permissions to remove the assigned staff.", status: :unauthorized
         return
      end
      begin
         project = Project.find(params[:id])
         project.clear_assignment(current_user)
         logger.info("Project[#{project.id}] is now unassigned ")
         render plain: "OK"
      rescue Exception=>e
         logger.error("Unassign project FAILED: #{e.class.name} - #{e.message}}")
         render plain: "#{e.class.name}: #{e.message}}", status: :internal_server_error
      end
   end

   member_action :assign, :method => :post do
      project = Project.find(params[:id])
      user = StaffMember.find(params[:user])
      if !project.assignable?(user, current_user)
         logger.info("Project[#{project.id}] unable to assign staff_member[#{user.id}]: #{user.computing_id}. Not claimable.")
         render plain: "#{user.full_name} cannot be assigned this project. Required skills are missing.", status: :bad_request
         return
      end
      begin
         project.assign_to(user)
         logger.info("Project[#{project.id}] assigned to staff_member[#{user.id}]: #{user.computing_id} by #{current_user.computing_id}")
         render json: {id: user.id, name: "#{user.full_name} (#{user.computing_id})"}, status: :ok
      rescue Exception=>e
         logger.error("Assign project FAILED: #{e.class.name} - #{e.message}}")
         render plain: "#{e.class.name}: #{e.message}}", status: :internal_server_error
      end
   end

   member_action :claim, :method => :put do
      url = "/admin/projects"
      url = "/admin/projects/#{params[:id]}" if !params[:details].nil?
      project = Project.find(params[:id])
      if !project.assignable?(current_user, nil)
         redirect_to url, :notice => "You don't have the required skills to claim this project"
         return
      end
      if !project.owner.nil? && !(current_user.admin? || current_user.supervisor?)
         redirect_to url, :notice => "#{project.owner.full_name} has already claimed project #{project.id}"
         return
      end
      begin
         project.assign_to(current_user)
         logger.info("Project[#{project.id}] claimed by staff_member[#{current_user.id}]: #{current_user.computing_id} ")
         redirect_to url, :notice => "You have claimed project #{project.id}"
      rescue Exception=>e
         logger.error("Claim project FAILED: #{e.class.name} - #{e.message}}")
         redirect_to url, :notice => "Unable to claim project #{project.id}"
      end
   end

   member_action :assignable, :method => :get do
      project = Project.find(params[:id])
      out = []
      StaffMember.candidates_for(project.category).each do |sm|
         out << {id: sm.id, name: "#{sm.full_name} - #{sm.role.capitalize}"}
      end
      render json: out
   end

   controller do
      def scoped_collection
         if params[:action] == 'index'
            if !current_user.admin? && !current_user.supervisor?
               ids = []
               current_user.skills.each do |s|
                  ids << s.id
               end
               # Students only see projects that match their skills
               end_of_association_chain = Project.where("category_id in (#{ids.join(',')})")
            else
               # Admin and supervisor see all projects
               end_of_association_chain = Project.all.order(due_on: :asc)
            end
         else
            end_of_association_chain = Project.where(id: params[:id])
         end
      end
  end
end
