ActiveAdmin.register Unit do
  menu :priority => 5

  # strong paramters handling
  permit_params :unit_status, :unit_extent_estimated, :unit_extent_actual, :special_instructions, :staff_notes,
     :intended_use_id, :remove_watermark, :date_materials_received, :date_materials_returned, :date_archived,
     :date_patron_deliverables_ready, :patron_source_url, :order_id, :metadata_id, :complete_scan,
     :include_in_dl, :date_dl_deliverables_ready

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
  filter :staff_notes
  filter :special_instructions
  filter :date_archived
  filter :date_dl_deliverables_ready
  filter :department, :as => :select
  filter :reorder, :as => :select
  filter :complete_scan, :as => :select


  csv do
    column :id
    column :metadata_title
    column("Date Archived") {|unit| format_date(unit.date_archived)}
    column("Date DL Deliverables Ready") {|unit| format_date(unit.date_dl_deliverables_ready)}
    column :master_files_count
  end

  actions :all, :except => [:destroy]
  config.clear_action_items!

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
     link_to "OCR", "/admin/ocr?u=#{unit.id}"  if !current_user.viewer? && !current_user.student? && !unit.reorder && unit.master_files_count > 0
  end

  batch_action :approve_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'approved') }
    flash[:notice] = "Units #{selection.join(", ")} are now approved."
    redirect_to "/admin/units"
  end

  batch_action :cancel_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'canceled') }
    flash[:notice] = "Units #{selection.join(", ")} are now canceled."
    redirect_to "/admin/units"
  end

  batch_action :check_condition_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'condition') }
    flash[:notice] = "Units #{selection.join(", ")} need to be vetted for condition."
    redirect_to "/admin/units"
  end

  batch_action :check_copyright_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:unit_status, 'copyright') }
    flash[:notice] = "Units #{selection.join(", ")} need to be vetted for copyright."
    redirect_to "/admin/units"
  end

  batch_action :include_in_dl_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:include_in_dl, true) }
    flash[:notice] = "Units #{selection.join(", ")} have been marked for inclusion in the Digital Library."
    redirect_to "/admin/units"
  end

  batch_action :exclude_from_dl_units do |selection|
    Unit.find(selection).each {|s| s.update_attribute(:include_in_dl, false) }
    flash[:notice] = "Units #{selection.join(", ")} have been marked for exclusion from the Digital Library."
    redirect_to "/admin/units"
  end

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
     unit = Unit.find(params[:id])
     job_id = CloneMasterFiles.exec({unit: unit, list: params[:masterfiles]})
     render :text=>job_id, status: :ok
  end
  member_action :clone_status, method: :get do
     job = JobStatus.find(params[:job])
     render :text=>"Invalid job", status: :bad_request and return if job.name != "CloneMasterFiles"
     render :text=>"Not for this unit", status: :conflict and return if job.originator_id != params[:id].to_i
     render :text=>job.status, status: :ok
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

  # Indev view ================================================================
  #
  index do
    selectable_column
    column :id
    column("Status") do |unit|
      status_tag(unit.unit_status)
    end
    column ("Metadata Record") do |unit|
      div do
         if !unit.metadata.nil?
            link_to "#{unit.metadata.title}", "/admin/#{unit.metadata.url_fragment}/#{unit.metadata.id}"
         end
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
    column :date_dl_deliverables_ready do |unit|
      format_date(unit.date_dl_deliverables_ready)
    end
    column :intended_use
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
         if unit.master_files_count > 0 && unit.reorder == false
            div do
               link_to "OCR", "/admin/ocr?u=#{unit.id}"
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
    div :class => 'two-column' do
      panel "General Information" do
        attributes_table_for unit do
          row ("Status") do |unit|
            status_tag(unit.unit_status)
          end
          row :unit_extent_estimated
          row :unit_extent_actual
          row :patron_source_url
          row :special_instructions do |unit|
            raw(unit.special_instructions.to_s.gsub(/\n/, '<br/>'))
          end
          row :staff_notes do |unit|
            raw(unit.staff_notes.to_s.gsub(/\n/, '<br/>'))
          end
          row :complete_scan
        end
      end
    end

    div :class => 'two-column' do
      panel "Patron Request" do
        attributes_table_for unit do
          row :intended_use
          row :intended_use_deliverable_format
          row :intended_use_deliverable_resolution
          row :remove_watermark do |unit|
            format_boolean_as_yes_no(unit.remove_watermark)
          end
          if unit.reorder == false
             row("Date Delivered to DigiServ") do |unit|
               format_date(unit.date_materials_received)
             end
             row("Date Returned from DigiServ") do |unit|
               format_date(unit.date_materials_returned)
             end
             row :date_archived do |unit|
               format_datetime(unit.date_archived)
             end
          end
          row :date_patron_deliverables_ready do |unit|
            format_datetime(unit.date_patron_deliverables_ready)
          end
        end
      end
    end

    if !unit.reorder
       div :class => "columns-none" do
         panel "Digital Library Information", :toggle => 'show' do
           attributes_table_for unit do
             row ("In Digital Library?") do |unit|
               format_boolean_as_yes_no(unit.include_in_dl)
             end
             row :date_dl_deliverables_ready do |unit|
               format_datetime(unit.date_dl_deliverables_ready)
             end
           end
         end
       end
    end

    # Attachments info ========================================================
    #
    div :class => "columns-none" do
      panel "Attachments", :toggle => 'show' do
         div :class=>'panel-buttons' do
            if unit.unit_status != "approved"
              div do "Attachments cannot be aded to unapproved units." end
            else
              add_btn = "<span id='add-attachment' class='mf-action-button'>Add Attachment</a>"
              raw("#{add_btn}")
           end
         end
         if unit.attachments.count > 0
            table_for unit.attachments do |att|
               column :filename
               column :description
               column("") do |a|
                  div do
                    link_to "Download", "/admin/units/#{unit.id}/download?attachment=#{a.id}", :class => "member_link view_link"
                  end
                  div do
                    msg = "Are you sure you want to delete atachment '#{a.filename}'?"
                    link_to "Delete", "/admin/units/#{unit.id}/remove?attachment=#{a.id}",
                        :class => "member_link view_link", :method => :delete, data: { confirm: msg }
                  end
               end
            end
         else
            div "No attachments are associated with this unit."
         end
      end
    end
    render :partial=>"modals", :locals=>{ unit: unit}

    # Master Files info =======================================================
    #
    div :class => "columns-none" do
      panel "Master Files", :toggle => 'show' do
         if unit.master_files.count == 0
            div id: "masterfile-list" do
               "No master files are ssociated with this unit."
            end
            if unit.intended_use.id != 110 # Digital Collection Building
               div :class=>'panel-buttons' do
                  if unit.unit_status != "approved"
                    div do "Master files cannot be aded to unapproved units." end
                  else
                     add_btn = "<span id='copy-existing' class='mf-action-button'>Use Existing Masterfiles</a>"
                     raw("#{add_btn}")
                  end
               end
            end
            render "clone_masterfiles", :context => self
         else
            render "unit_masterfiles", :context => self
         end
      end
    end

    if !current_user.viewer?
       div :class => "columns-none" do
         panel "Digitization Workflow Notes", :class=>"notes", :toggle => 'hide' do
            if unit.notes.count == 0
               raw("<p>There are no notes associated with this unit</p>")
            else
               unit.notes.order(created_at: :desc).each do |n|
                  render partial: "/admin/projects/note", locals: {note: n}
               end
            end
         end
       end
    end
  end

  # EDIT page =================================================================
  #
  form :partial => "edit"

  sidebar "Related Information", :only => [:show] do
    attributes_table_for unit do
      row "Metadata" do |unit|
         if !unit.metadata.nil?
            disp = "<a href='/admin/#{unit.metadata.url_fragment}/#{unit.metadata.id}'><span>#{unit.metadata.pid}<br/>#{unit.metadata.title}</span></a>"
            raw( disp)
         end
      end
      row :order do |unit|
        link_to "##{unit.order.id}", admin_order_path(unit.order.id)
      end
      row :master_files do |unit|
        link_to "#{unit.master_files_count}", admin_master_files_path(:q => {:unit_id_eq => unit.id})
      end
      row :customer
      row :agency
      row :project
    end
  end

  # XML Upload / Download
  sidebar :bulk_actions, :only => :show,  if: proc{ !current_user.viewer? && !current_user.student? } do
     if unit.unit_status != "approved"
        div do "Unit has not been approved. No bulk actions can be taken." end
     else
        div :class => 'workflow_button' do
           button_to "XML Upload", bulk_upload_xml_admin_unit_path, :method => :put
        end
        if unit.has_xml_masterfiles?
           div :class => 'workflow_button' do
              button_to "XML Download", bulk_download_xml_admin_unit_path, :method => :put
           end
           div :class => 'workflow_button' do
             raw("<span class='admin-button' id='update-dl-settings'>Update DL Settings</span>")
          end
        end
     end
  end

  sidebar :approval_workflow, :only => :show,  if: proc{ !current_user.viewer? && !current_user.student? && !unit.reorder && !unit.ingested? } do
    if unit.project.nil?
       approved = unit.unit_status == 'approved' && unit.order.order_status == 'approved'
       div :class => 'workflow_button' do
         cn = "admin-button"
         cn << " disabled" if !approved
         raw("<span class='#{cn}' id='show-create-digitization-project'>Create Digitization Project</span>")
       end
       if !approved
          div class: "admin-button-note" do "Cannot create project, unit has not been approved." end
       end
    end

    if unit.date_materials_received.nil? # i.e. Material has yet to be checked out to Digital Production Group
      div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_admin_unit_path, :method => :put end
      div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_admin_unit_path, :method => :put, :disabled => true end
    elsif unit.date_materials_received # i.e. Material has been checked out to Digital Production Group
      if unit.date_materials_returned.nil? # i.e. Material has been checkedout to Digital Production Group but not yet returned
        div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_admin_unit_path, :method => :put, :disabled => true end
        div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_admin_unit_path, :method => :put end
      else
        div :class => 'workflow_button' do button_to "Check out to DigiServ", checkout_to_digiserv_admin_unit_path, :method => :put, :disabled => true end
        div :class => 'workflow_button' do button_to "Check in from DigiServ", checkin_from_digiserv_admin_unit_path, :method => :put, :disabled => true end
      end
    end
  end

  sidebar "Delivery Workflow", :only => [:show] do
    if !current_user.viewer? && !current_user.student?
       if unit.has_in_process_files?
            if unit.date_archived.blank? && unit.reorder == false
              div :class => 'workflow_button' do button_to "QA Unit Data", qa_unit_data_admin_unit_path , :method => :put end
              div :class => 'workflow_button' do button_to "QA Filesystem and XML", qa_filesystem_and_iview_xml_admin_unit_path , :method => :put end
              div :class => 'workflow_button' do button_to "Create Master File Records", import_unit_iview_xml_admin_unit_path, :method => :put end
              div :class => 'workflow_button' do button_to "Send Unit to Archive", send_unit_to_archive_admin_unit_path, :method => :put end
            end
            if unit.intended_use != 'Digital Collection Buidling'
               if !unit.date_patron_deliverables_ready
                  div :class => 'workflow_button' do
                     button_to "Generate Deliverables", check_unit_delivery_mode_admin_unit_path, :method => :put
                  end
                  if unit.reorder && unit.order.all_reorders_ready? && unit.order.units.count > 1
                     div do hr :class=>'sidebar-sep' end
                     div :class => 'workflow_button' do
                        button_to "Generate All Deliverables", generate_all_deliverables_admin_unit_path, :method => :put
                     end
                     div do "Generate deliverables for all units in this order." end
                  end
               else
                   div :class => 'workflow_button' do
                      button_to "Regenerate Deliverables", regenerate_deliverables_admin_unit_path, :method => :put
                   end
               end
            end
       else
          if unit.date_patron_deliverables_ready && unit.intended_use != 'Digital Collection Buidling'
             if unit.date_patron_deliverables_ready
                div :class => 'workflow_button' do button_to "Regenerate Deliverables", regenerate_deliverables_admin_unit_path, :method => :put end
             end
          else
            div do "Files for this unit do not reside in the finalization in-process directory. No work can be done on them." end
          end
       end
    end

    if unit.date_archived
      div :class => 'workflow_button' do button_to "Download Unit From Archive", copy_from_archive_admin_unit_path(unit.id), :method => :put end
      div :class => 'workflow_button' do
         raw("<a class='admin-button' href='/admin/units/#{unit.id}/download_unit_xml' target='_blank'>Download Unit XML Archive</a>")
      end
    else
      if  unit.reorder == false
         div do "This unit cannot be downloaded because it is not archived." end
      end
    end
  end

  sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? && !current_user.student? && (unit.ready_for_repo? || unit.in_dl?) } do
    if unit.ready_for_repo?
      div :class => 'workflow_button' do
         button_to "Put into Digital Library", start_ingest_from_archive_admin_unit_path(), :method => :put
      end
    end
    if unit.in_dl?
      div :class => 'workflow_button' do
         button_to "Publish All", publish_admin_unit_path(), :method => :put
      end
      div :class => 'workflow_button' do
         button_to "Publish to Digital Library Test", publish_to_test_admin_unit_path(), :method => :put
      end
    else
      div :class => 'workflow_button' do
         button_to "Put into Digital Library Test", publish_to_test_admin_unit_path(), :method => :put
      end
    end
  end

  action_item :previous, :only => :show do
    link_to("Previous", admin_unit_path(unit.previous)) unless unit.previous.nil?
  end

  action_item :next, :only => :show do
    link_to("Next", admin_unit_path(unit.next)) unless unit.next.nil?
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

  member_action :attachment, :method => :post do
     unit = Unit.find(params[:id])
     filename = params[:attachment].original_filename
     upload_file = params[:attachment].tempfile.path
     begin
        AttachFile.exec_now({unit: unit, filename: filename, tmpfile: upload_file, description: params[:description]})
        render nothing: true
     rescue Exception => e
        Rails.logger.error e.to_s
        render text: "Attachment '#{filename}' FAILED: #{e.to_s}", status:  :error
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
     if t.save
        render text: t.id, status: :ok
     else
        render text: t.errors.full_messages.to_sentence, status: :error
     end
  end

  # Member actions for workflow
  member_action :generate_all_deliverables, :method=>:put do
     unit = Unit.find(params[:id])
     GenerateAllReorderDeliverables.exec({order: unit.order})
     redirect_to "/admin/units/#{params[:id]}", :notice => "Generating deliverables for all units in the order."
  end

  member_action :regenerate_deliverables, :method=>:put do
     unit = Unit.find(params[:id])
     RecreatePatronDeliverables.exec({unit: unit})
     redirect_to "/admin/units/#{params[:id]}", :notice => "Regenerating unit deliverables."
  end

  member_action :check_unit_delivery_mode, :method => :put do
    Unit.find(params[:id]).check_unit_delivery_mode
    redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at the checking of the unit's delivery mode."
  end

  member_action :download_unit_xml, :method => :get do
     unit = Unit.find(params[:id])
     unit_dir = "%09d" % unit.id
     source_fn = File.join(ARCHIVE_DIR, unit_dir, "#{unit_dir}.xml")
     if File.exists? source_fn
        send_file(source_fn)
     else
        render text: "Unit XML does not exist in the archive."
     end
  end

  member_action :copy_from_archive, :method => :put do
    Unit.find(params[:id]).get_from_stornext( current_user.computing_id )
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit #{params[:id]} is now being downloaded to #{PRODUCTION_SCAN_FROM_ARCHIVE_DIR} under your username."
  end

  member_action :import_unit_iview_xml, :method => :put do
    Unit.find(params[:id]).import_unit_iview_xml
    redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at the importation of the Iview XML and creation of master files."
  end

  member_action :qa_filesystem_and_iview_xml, :method => :put do
    Unit.find(params[:id]).qa_filesystem_and_iview_xml
    redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at QA of filesystem and Iview XML."
  end

  member_action :qa_unit_data, :method => :put do
    Unit.find(params[:id]).qa_unit_data
    redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at QA unit data."
  end

  member_action :send_unit_to_archive, :method => :put do
    Unit.find(params[:id]).send_unit_to_archive
    redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at the archiving of the unit."
  end

  member_action :start_ingest_from_archive, :method => :put do
    unit = Unit.find(params[:id])
    StartIngestFromArchive.exec( {:unit => unit})
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit being put into digital library."
  end

  member_action :publish_to_test, :method => :put do
     unit = Unit.find(params[:id])
     PublishToTest.exec({unit: unit})
     redirect_to "/admin/units/#{params[:id]}", :notice => "Unit is being published to test"
  end

  member_action :publish, :method => :put do
    unit = Unit.find(params[:id])
    now = Time.now
    unit.metadata.update(date_dl_update: now)
    unit.master_files.each do |mf|
      mf.update(date_dl_update: now)
      if mf.metadata.id != unit.metadata.id
         if mf.metadata.date_dl_ingest.blank?
            if mf.metadata.date_dl_update.blank?
               mf.metadata.update(date_dl_ingest: now)
            else
               mf.metadata.update(date_dl_ingest: mf.metadata.date_dl_update, date_dl_update: now)
            end
         else
            mf.metadata.update(date_dl_update: now)
         end
      end
    end
    logger.info "Unit #{unit.id} and #{unit.master_files_count} master files have been flagged for an update in the DL"
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit flagged for Publication"
  end

  member_action :bulk_upload_xml, :method => :put do
     BulkUploadXml.exec({unit_id: params[:id]})
     redirect_to "/admin/units/#{params[:id]}", :notice => "Uploading XML for all mastefiles of unit #{params[:id]}."
  end

  member_action :bulk_download_xml, :method => :put do
     BulkDownloadXml.exec({unit_id: params[:id], user: current_user} )
     redirect_to "/admin/units/#{params[:id]}", :notice => "Downloading XML for unit #{params[:id]}. When complete, you will receive an email."
  end

  member_action :checkout_to_digiserv, :method => :put do
    Unit.find(params[:id]).update_attribute(:date_materials_received, Time.now)
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit #{params[:id]} is now checked out to Digital Production Group."
  end

  member_action :checkin_from_digiserv, :method => :put do
    Unit.find(params[:id]).update_attribute(:date_materials_returned, Time.now)
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit #{params[:id]} has been returned from Digital Production Group."
  end

  member_action :add, :method => :post do
    unit = Unit.find(params[:id])
    job_id = AddMasterFiles.exec({unit: unit})
    render :text=>job_id, status: :ok
  end
  member_action :replace, :method => :post do
    unit = Unit.find(params[:id])
    job_id = ReplaceMasterFiles.exec({unit: unit})
    render :text=>job_id, status: :ok
  end
  member_action :delete, :method => :post do
    unit = Unit.find(params[:id])
    filenames = params[:filenames]
    job_id = DeleteMasterFiles.exec({unit: unit, filenames: filenames})
    render :text=>job_id, status: :ok
  end
  member_action :status, method: :get do
     job = JobStatus.find(params[:job])
     job_type = params[:type]
     type_pairings = { "add"=>"AddMasterFiles", "replace"=>"ReplaceMasterFiles", "delete"=>"DeleteMasterFiles"}
     render :text=>"Invalid job", status: :bad_request and return if job.name != type_pairings[job_type]
     render :text=>"Not for this unit", status: :conflict and return if job.originator_id != params[:id].to_i
     render :text=>job.status, status: :ok
  end

  collection_action :autocomplete, method: :get do
     suggestions = []
     like_keyword = "#{params[:query]}%"
     Unit.where("id like ?", like_keyword).each do |o|
        suggestions << "#{o.id}"
     end
     resp = {query: "Unit", suggestions: suggestions}
     render json: resp, status: :ok
  end

  controller do
     before_filter :get_digital_collection_units, only: [:show]
     def get_digital_collection_units
        metadata = resource.metadata
        @dc_units = []
        Unit.where(metadata: metadata).where(intended_use_id: 110).each do |u|
           @dc_units << u.id
        end
     end
  end
end
