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

   sidebar :bulk_actions, :only => :show,  if: proc{ !current_user.viewer? && !current_user.student? && unit.master_files_count > 0 } do
      render "bulk_actions", :context => self
   end

   sidebar "Workflow", :only => [:show],  if: proc{ unit.unit_status != "unapproved" && unit.unit_status != "canceled"}  do
      render "delivery_workflow", :context=>self
   end

   sidebar "Digital Library Workflow", :only => [:show],
      if: proc{ !unit.metadata.nil? && unit.metadata.type != "ExternalMetadata" && !current_user.viewer? && !current_user.student? && (unit.ready_for_repo? || unit.in_dl? ) } do
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
   member_action :bulk_settings_update, method: :post do
      unit = Unit.find(params[:id])
      discoverability = (params[:discoverable] == "yes")
      rights = UseRight.find(params[:rights].to_i)
      avail = AvailabilityPolicy.find(params[:availability].to_i)
      unit.master_files.each do |mf|
         mf.metadata.update(discoverability: discoverability, use_right: rights, availability_policy: avail)
      end
      render :nothing=>true
   end

   member_action :clone_master_files, method: :post do
      job_id = CloneMasterFiles.exec({unit_id: params[:id], list: params[:masterfiles]})
      render plain: job_id, status: :ok
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
      FinalizeUnit.exec( {unit_id: params[:id]} )
      flash[:notice] = "Finalizing unit"
      redirect_to "/admin/units/#{params[:id]}"
   end

   member_action :download, :method => :get do
      unit = Unit.find(params[:id])
      att = Attachment.find(params[:attachment])
      unit_dir = "%09d" % unit.id
      dest_dir = File.join(ARCHIVE_DIR, unit_dir, "attachments" )
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
      unit_dir = "%09d" % unit.id
      dest_dir = File.join(ARCHIVE_DIR, unit_dir, "attachments" )
      dest_file = File.join(dest_dir, att.filename)
      if File.exist? dest_file
         FileUtils.rm(dest_file)
      end
      att.destroy
      redirect_to "/admin/units/#{params[:id]}", :notice => "Attachment deleted"
   end

   member_action :ocr, :method => :post do
      unit = Unit.find(param[:id])
      OCR.unit(unit)
      redirect_to "/admin/units/#{params[:id]}", :notice => "OCR started. Check job status page for updates"
   end

   member_action :xml_transform, :method => :post do
      # copy the file to /tmp so we have more control over its lifecycle
      upload_file = params[:xslfile].tempfile.path
      xsl_uuid =  SecureRandom.uuid
      dest_dir = File.join(Rails.root, "tmp", "xsl")
      FileUtils.mkdir_p dest_dir
      dest = File.join(dest_dir, "#{xsl_uuid}.xsl")
      FileUtils.cp(upload_file, dest)
      unit = Unit.find(params[:id])
      BulkTransformXml.exec({user: current_user, mode: :unit, unit: unit, xsl_file: dest})
      render plain: "ok"
   end

   member_action :attachment, :method => :post do
      unit = Unit.find(params[:id])
      filename = params[:attachment].original_filename
      upload_file = params[:attachment].tempfile.path
      begin
         AttachFile.exec_now({unit: unit, filename: filename, tmpfile: upload_file, description: params[:description]})
         render plain: "OK"
      rescue Exception => e
         Rails.logger.error e.to_s
         render plain: "Attachment '#{filename}' FAILED: #{e.to_s}", status:  :error
      end
   end

   member_action :project, :method => :post do
      w = Workflow.find(params[:workflow])
      u = Unit.find(params[:id])
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
         render plain: t.errors.full_messages.to_sentence, status: :error
      end
   end

   member_action :regenerate_deliverables, :method=>:put do
      RecreatePatronDeliverables.exec({unit_id: params[:id]})
      redirect_to "/admin/units/#{params[:id]}", :notice => "Regenerating unit deliverables."
   end

   member_action :check_unit_delivery_mode, :method => :put do
      CheckUnitDeliveryMode.exec( {:unit_id => params[:id]} )
      redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at the checking of the unit's delivery mode."
   end

   member_action :download_unit_xml, :method => :get do
      unit = Unit.find(params[:id])
      unit_dir = "%09d" % unit.id
      source_fn = File.join(ARCHIVE_DIR, unit_dir, "#{unit_dir}.xml")
      if File.exists? source_fn
         send_file(source_fn)
      else
         render plain: "Unit XML does not exist in the archive."
      end
   end

   member_action :copy_from_archive, :method => :put do
      CopyArchivedFilesToProduction.exec( {:unit_id => params[:id], :computing_id => current_user.computing_id })
      redirect_to "/admin/units/#{params[:id]}", :notice => "Unit #{params[:id]} is now being downloaded to #{Finder.scan_from_archive_dir} under your username."
   end

   member_action :import_unit_iview_xml, :method => :put do
      unit_dir = "%09d" % params[:id].to_i
      unit = Unit.find(params[:id])
      ImportUnitIviewXML.exec( {:unit_id => params[:id], :path => "#{Finder.finalization_dir(unit, :in_process)}/#{unit_dir}.xml"})
      redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at the importation of the Iview XML and creation of master files."
   end

   member_action :qa_filesystem_and_iview_xml, :method => :put do
      QaFilesystemAndIviewXml.exec( {:unit_id => params[:id]} )
      redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at QA of filesystem and Iview XML."
   end

   member_action :qa_unit_data, :method => :put do
      QaUnitData.exec( {:unit_id => params[:id]})
      redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at QA unit data."
   end

   member_action :send_unit_to_archive, :method => :put do
      SendUnitToArchive.exec( {:unit_id => params[:id]})
      redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at the archiving of the unit."
   end

   member_action :publish_to_test, :method => :put do
      PublishToDL.exec({unit_id: params[:id], mode: :test})
      redirect_to "/admin/units/#{params[:id]}", :notice => "Unit is being published to test"
   end

   member_action :publish, :method => :put do
      PublishToDL.exec({unit_id: params[:id], mode: :production})
      redirect_to "/admin/units/#{params[:id]}", :notice => "Unit published to DL. It will be available tomorrow."
   end

   member_action :bulk_upload_xml, :method => :put do
      BulkUploadXml.exec({unit_id: params[:id], user: current_user})
      redirect_to "/admin/units/#{params[:id]}", :notice => "Uploading XML for all mastefiles of unit #{params[:id]}."
   end

   member_action :bulk_download_xml, :method => :put do
      BulkDownloadXml.exec({unit_id: params[:id], user: current_user} )
      redirect_to "/admin/units/#{params[:id]}", :notice => "Downloading XML for unit #{params[:id]}. When complete, you will receive an email."
   end

   member_action :add, :method => :post do
      job_id = AddMasterFiles.exec({unit_id: params[:id]})
      render plain: job_id, status: :ok
   end
   member_action :replace, :method => :post do
      job_id = ReplaceMasterFiles.exec({unit_id: params[:id]})
      render plain: job_id, status: :ok
   end
   member_action :delete, :method => :post do
      job_id = DeleteMasterFiles.exec({unit_id: params[:id], filenames: params[:filenames]})
      render plain: job_id, status: :ok
   end
   member_action :renumber, :method => :post do
      job_id = RenumberMasterFiles.exec({unit_id: params[:id], filenames: params[:filenames], new_start_num: params[:new_start_num]})
      render plain: job_id, status: :ok
   end
   member_action :job_status, method: :get do
      job = JobStatus.find(params[:job])
      job_type = params[:type]
      type_pairings = { "add"=>"AddMasterFiles", "replace"=>"ReplaceMasterFiles", "delete"=>"DeleteMasterFiles", "renumber"=>"RenumberMasterFiles"}
      render plain: "Invalid job", status: :bad_request and return if job.name != type_pairings[job_type]
      render plain: "Not for this unit", status: :conflict and return if job.originator_id != params[:id].to_i
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
