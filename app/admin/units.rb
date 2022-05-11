ActiveAdmin.register Unit do
   menu :priority => 5
   config.per_page = [30, 50, 100, 250]

   # eager load to preven n+1 queries, and improve performance
   includes :metadata, :order, :department, :agency

   # strong paramters handling
   permit_params :unit_status, :unit_extent_estimated, :unit_extent_actual, :special_instructions, :staff_notes,
      :intended_use_id, :remove_watermark, :date_archived,
      :date_patron_deliverables_ready, :patron_source_url, :order_id, :metadata_id, :complete_scan,
      :include_in_dl, :date_dl_deliverables_ready, :throw_away, :ocr_master_files

   scope :all, :default => true
   scope :approved
   scope :unapproved
   scope :awaiting_copyright_approval
   scope :awaiting_condition_approval
   scope :canceled
   scope :uncompleted_units_of_partially_completed_orders
   scope :ready_for_repo

   filter :id_eq, :label=>"ID"
   filter :order_id_eq, :label => "Order ID"
   filter :metadata_call_number_starts_with, :as => :string, :label => "Call Number"
   filter :metadata_title_contains, :as => :string, :label => "Metadata Title"
   filter :agency, :as => :select, collection: Agency.pluck(:name, :id)
   filter :customer_last_name_starts_with, :label => "Customer Last Name"
   filter :staff_notes
   filter :special_instructions
   filter :date_archived
   filter :date_dl_deliverables_ready
   filter :intended_use, :as => :select
   filter :department, :as => :select
   filter :reorder, :as => :select
   filter :complete_scan, :as => :select
   filter :master_files_count, :as => :numeric

   csv do
      column :id
      column :metadata_title
      column ("Call Number") do |unit|
         if unit.metadata.nil? || !unit.metadata.nil? && unit.metadata.type != "SirsiMetadata"
            "N/A"
         else
            "#{unit.metadata.call_number}"
         end
      end
      column :intended_use do |unit|
         if unit.intended_use.nil?
            "N/A"
         else
            unit.intended_use.description
         end
      end
      column("Date Archived") {|unit| format_date(unit.date_archived)}
      column("Date DL Deliverables Ready") {|unit| format_date(unit.date_dl_deliverables_ready)}
      column :master_files_count
   end

   actions :all, :except => [:destroy]
   config.clear_action_items!

   batch_action :approve_units do |selection|
      Unit.find(selection).each {|s| s.update(unit_status: 'approved') }
      flash[:notice] = "Units #{selection.join(", ")} are now approved."
      redirect_to "/admin/units"
   end

   batch_action :cancel_units do |selection|
      Unit.find(selection).each {|s| s.update(unit_status: 'canceled') }
      flash[:notice] = "Units #{selection.join(", ")} are now canceled."
      redirect_to "/admin/units"
   end

   batch_action :check_condition_units do |selection|
      Unit.find(selection).each {|s| s.update(unit_status: 'condition') }
      flash[:notice] = "Units #{selection.join(", ")} need to be vetted for condition."
      redirect_to "/admin/units"
   end

   batch_action :check_copyright_units do |selection|
      Unit.find(selection).each {|s| s.update(unit_status: 'copyright') }
      flash[:notice] = "Units #{selection.join(", ")} need to be vetted for copyright."
      redirect_to "/admin/units"
   end

   batch_action :include_in_dl_units do |selection|
      Unit.find(selection).each {|s| s.update(include_in_dl: true) }
      flash[:notice] = "Units #{selection.join(", ")} have been marked for inclusion in the Digital Library."
      redirect_to "/admin/units"
   end

   batch_action :exclude_from_dl_units do |selection|
      Unit.find(selection).each {|s| s.update(include_in_dl: false) }
      flash[:notice] = "Units #{selection.join(", ")} have been marked for exclusion from the Digital Library."
      redirect_to "/admin/units"
   end

   # Index view ================================================================
   #
   index do
      selectable_column
      column :id
      column("Status") do |unit|
         status_tag(unit.unit_status)
      end
      column ("Metadata Record") do |unit|
         div do
            if !unit.metadata.nil? && !unit.metadata.title.nil?
               link_to "#{unit.metadata.title.truncate(50, separator: ' ')}", "/admin/#{unit.metadata.url_fragment}/#{unit.metadata.id}"
            end
         end
      end
      column("Call Number") do |unit|
         if unit.metadata.nil? || !unit.metadata.nil? && unit.metadata.type != "SirsiMetadata"
            "N/A"
         else
            "#{unit.metadata.call_number}"
         end
      end
      column ("Reorder?") do |unit|
         format_boolean_as_yes_no(unit.reorder)
      end
      column ("In DL?") do |unit|
         format_boolean_as_yes_no(unit.include_in_dl)
      end
      column :date_archived do |unit|
         format_date(unit.date_archived)
      end
      column ("Date DL\nDeliverables Ready")  do |unit|
         format_date(unit.date_dl_deliverables_ready)
      end
      column :intended_use do |unit|
         unit.intended_use.description if !unit.intended_use.nil?
      end
      column("Master Files") do |unit|
         link_to unit.master_files_count, admin_master_files_path(:q => {:unit_id_eq => unit.id})
      end
      column("") do |unit|
         div do
            link_to "Details", resource_path(unit), :class => "member_link view_link"
         end
         if !current_user.viewer? && !current_user.student?
            div do
               link_to I18n.t('active_admin.edit'), edit_resource_path(unit), :class => "member_link edit_link"
            end
            if unit.master_files_count > 0 && unit.reorder == false && unit.ocr_candidate?
               div do
                  link_to "OCR", "/admin/units/#{unit.id}/ocr"
               end
            end
         end
         if !unit.metadata.nil? && unit.master_files_count > 0 && unit.reorder == false
            div do
               link_to "PDF", "#{Settings.pdf_url}/#{unit.metadata.pid}?unit=#{unit.id}", target: "_blank"
            end
         end
      end
   end

   # Show view =================================================================
   #
   show :title => lambda{|unit|  unit.reorder ? "Unit ##{unit.id} : RE-ORDER" : "Unit ##{unit.id}"} do |unit|
      err = unit.last_error
      if !err.blank?
         render partial: "recent_error", locals: {job_id: err[:job] , error: err[:error]}
      end
      render "details", :context => self
      render "attachments", :context => self
      render "master_files", :context => self
      render "notes", :context => self
      render :partial=>"modals", :locals=>{ unit: unit}
   end

   # EDIT page =================================================================
   #
   form :partial => "edit"

   # Sidebars ==================================================================
   #
   sidebar "Related Information", :only => [:show] do
      render "related_info", :context => self
   end

   sidebar "Workflow", :only => [:show],
      if: proc{ !current_user.viewer? && !current_user.student? && unit.unit_status != "unapproved" && unit.unit_status != "canceled"}  do
      render "delivery_workflow", :context=>self
   end

   sidebar "Digital Library Workflow", :only => [:show],
      if: proc{ !unit.metadata.nil? && unit.metadata.type != "ExternalMetadata" && !current_user.viewer? && !current_user.student? } do
      render "dl_workflow", :context=>self
   end

   # ACTION ITEMS ==============================================================
   #
   action_item :previous, :only => :show do
      link_to("Previous", admin_unit_path(unit.previous)) unless unit.previous.nil?
   end

   action_item :next, :only => :show do
      link_to("Next", admin_unit_path(unit.next)) unless unit.next.nil?
   end

   action_item :new, :only => :index do
      raw("<a href='/admin/units/new'>New</a>") if !current_user.viewer? && !current_user.student?
   end
   action_item :edit, only: :show do
      link_to "Edit", edit_resource_path  if !current_user.viewer? && !current_user.student?
   end

   action_item :pdf, :only => :show do
      if !unit.metadata.nil? && unit.master_files_count > 0 && !unit.reorder
         raw("<a href='#{Settings.pdf_url}/#{unit.metadata.pid}?unit=#{unit.id}' target='_blank'>Download PDF</a>")
      end
   end
   action_item :ocr, only: :show do
      if !current_user.viewer? && !current_user.student? && !unit.reorder && unit.master_files_count > 0
         link_to "OCR", "/admin/units/#{unit.id}/ocr", method: :post
      end
   end

   # MEMBER ACTIONS ============================================================
   #
   member_action :clone_master_files, method: :post do
      resp = Job.submit("/units/#{params[:id]}/masterfiles/clone", params[:masterfiles])
      if resp.success?
         render plain: resp.job_id, status: :ok
      else
         render plain: resp.message, status: :internal_server_error
      end
   end

   member_action :clone_status, method: :get do
      job = JobStatus.find(params[:job])
      render plain: "Invalid job", status: :bad_request and return if job.name != "CloneMasterFiles"
      render plain: "Not for this unit", status: :conflict and return if job.originator_id != params[:id].to_i
      render plain: job.status, status: :ok
   end

   member_action :master_files, method: :get do
      page_size = 15
      page_idx = 0
      page_idx = params[:page].to_i()-1 if !params[:page].blank?
      cnt = MasterFile.where(unit_id: params[:id]).count
      items = []
      start_idx = page_idx*page_size
      end_idx = start_idx+page_size
      end_idx = cnt if end_idx > cnt
      maxpage = (cnt/page_size.to_f).ceil
      MasterFile.where(unit_id: params[:id]).limit(page_size).offset( start_idx ).each do |mf|
         next if mf.deaccessioned?
         items << { id: mf.id, filename: mf.filename, title: mf.title, thumb: mf.link_to_image(:small) }
      end
      out = {total: cnt, page: params[:page], maxpage: maxpage, start: start_idx+1, end: end_idx, masterfiles: items}
      render json: out, status: :ok
   end

   member_action :finalize_raw_images do
      resp = Job.submit("/units/#{params[:id]}/finalize", nil)
      if resp.success?
         redirect_to "/admin/units/#{params[:id]}", :notice => "Finalizing unit"
      else
         redirect_to "/admin/units/#{params[:id]}", :alert => "Unable to finalize unit: #{resp.message}"
      end
   end

   member_action :download, :method => :get do
      unit = Unit.find(params[:id])
      att = Attachment.find(params[:attachment])
      dest_dir = File.join(ARCHIVE_DIR, unit.directory, "attachments" )
      dest_file = File.join(dest_dir, att.filename)
      if File.exist? dest_file
         send_file dest_file
      else
         redirect_to "/admin/units/#{params[:id]}", :notice => "Unable to find source file for attachment!"
      end
   end

   member_action :remove, :method => :delete do
      unit = Unit.find(params[:id])
      att = Attachment.find(params[:attachment])
      dest_dir = File.join(ARCHIVE_DIR, unit.directory, "attachments" )
      dest_file = File.join(dest_dir, att.filename)
      if File.exist? dest_file
         FileUtils.rm(dest_file)
      end
      att.destroy
      redirect_to "/admin/units/#{params[:id]}", :notice => "Attachment deleted"
   end

   member_action :ocr, :method => :post do
      OCR.unit( Unit.find(params[:id]) )
      redirect_to "/admin/units/#{params[:id]}", :notice => "OCR started. Check job status page for updates"
   end

   member_action :attachment, :method => :post do
      success, err = Job.attach_file(params[:id], params[:attachment], params[:description])
      if success
         render plain: "OK"
      else
         render plain: "Attachment '#{filename}' FAILED: #{err}", status:  :internal_server_error
      end
   end

   member_action :project, :method => :post do
      w = Workflow.find(params[:workflow])
      u = Unit.find(params[:id])

      # Another user could have created a project for this unit while this
      # user was on the unit screen. Ensure no project exists for this unit before continuing
      if !u.project.nil?
         render plain: "A project already exists for this unit", status: :bad_request
         return
      end

      c = Category.find(params[:category])
      ic = params[:condition]
      note = params[:notes]
      t = Project.new(workflow: w, unit: u, priority: params[:priority].to_i,
         item_condition: ic.to_i, condition_note: note,
         category: c, due_on: params[:due])
      if w.name == "Manuscript"
         container_type = ContainerType.find(params[:container_type])
         t.container_type = container_type
      end
      if t.save
         msg = "Project created"
         AuditEvent.create(auditable: t, event: AuditEvent.events[:project_create], staff_member: current_user, details: msg)
         render plain: t.id, status: :ok
      else
         render plain: t.errors.full_messages.to_sentence, status: :internal_server_error
      end
   end

   member_action :generate_deliverables, :method=>:put do
      resp = Job.submit("/units/#{params[:id]}/deliverables", nil)
      if resp.success?
         redirect_to "/admin/units/#{params[:id]}", :notice => "Generating unit deliverables."
      else
         redirect_to "/admin/units/#{params[:id]}", :alert => "Unable to unit deliverables: #{resp.message}"
      end
   end

   member_action :complete_unit, :method=>:put do
      unit = Unit.find(params[:id])
      unit.update(unit_status: "done")
      redirect_to "/admin/units/#{params[:id]}", :notice => "Unit marked as done."
   end

   member_action :regenerate_iiifman, :method=>:put do
      unit = Unit.find(params[:id])
      md_pid = unit.metadata.pid
      iiif_url = "#{Settings.iiif_manifest_url}/pid/#{md_pid}?refresh=true"
      Rails.logger.info "Regenerate IIIF manifest with #{iiif_url}"
      resp = RestClient.get iiif_url
      if resp.code.to_i != 200
         redirect_to "/admin/units/#{params[:id]}", :flash => {
            :error => "Unable to generate IIIF manifest: #{resp.body}"
         }
      else
         redirect_to "/admin/units/#{params[:id]}", :notice => "IIIF manifest regenerated."
      end
   end

   member_action :copy_from_archive, :method => :put do
      resp = Job.submit("/units/#{params[:id]}/copy", {computeID: current_user.computing_id, filename: "all"})
      if resp.success?
         unit = Unit.find(params[:id])
         dest = File.join(Settings.production_mount, "from_archive", current_user.computing_id , unit.directory )
         redirect_to "/admin/units/#{params[:id]}", :notice => "Unit #{params[:id]} is now being downloaded to #{dest}."
      else
         redirect_to "/admin/units/#{params[:id]}", :alert => "Copy failed: #{resp.message}"
      end
   end

   member_action :publish, :method => :put do
      unit = Unit.find(params[:id])
      Virgo.publish(unit, Rails.logger)
      redirect_to "/admin/units/#{params[:id]}", :notice => "Unit has been published to Virgo."
   end

   member_action :add, :method => :post do
      resp = Job.submit("/units/#{params[:id]}/masterfiles/add", nil)
      if resp.success?
         render plain: resp.job_id, status: :ok
      else
         render plain: resp.message, status: :internal_server_error
      end
   end
   member_action :replace, :method => :post do
      resp = Job.submit("/units/#{params[:id]}/masterfiles/replace", nil)
      if resp.success?
         render plain: resp.job_id, status: :ok
      else
         render plain: resp.message, status: :internal_server_error
      end
   end
   member_action :delete, :method => :post do
      data = {filenames: params[:filenames] }
      resp = Job.submit("/units/#{params[:id]}/masterfiles/delete", data)
      if resp.success?
         render plain: resp.job_id, status: :ok
      else
         render plain: resp.message, status: :internal_server_error
      end
   end
   member_action :renumber, :method => :post do
      data = {filenames: params[:filenames], "startNum":  params[:new_start_num].to_i}
      resp = Job.submit("/units/#{params[:id]}/masterfiles/renumber", data)
      if resp.success?
         render plain: "finished", status: :ok
      else
         render plain: resp.message, status: :internal_server_error
      end
   end
   member_action :job_status, method: :get do
      job = JobStatus.find(params[:job])
      render plain: job.status, status: :ok
   end

   controller do
      before_action :get_clone_src_units, only: [:show]
      def get_clone_src_units
         # Get a list of units that can be used as a source for cloning masterfiles
         metadata = resource.metadata
         @dc_units = []
         q = "master_files_count > 0 and reorder = 0 and id <> #{resource.id} and throw_away=false"
         q << " and metadata_id = #{resource.metadata_id}" if !resource.metadata_id.nil?
         Unit.where(q).each do |u|
            @dc_units << u.id
         end
      end
   end
end
