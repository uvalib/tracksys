ActiveAdmin.register Unit do
  menu :priority => 4

  # strong paramters handling
  permit_params :unit_status, :unit_extent_estimated, :unit_extent_actual, :special_instructions, :staff_notes,
     :intended_use_id, :remove_watermark, :date_materials_received, :date_materials_returned, :date_archived,
     :date_patron_deliverables_ready, :patron_source_url, :order_id, :metadata_id, :indexing_scenario_id, :complete_scan,
     :include_in_dl, :master_file_discoverability, :date_queued_for_ingest, :date_dl_deliverables_ready

  scope :all, :default => true
  scope :approved
  scope :unapproved
  scope :awaiting_copyright_approval
  scope :awaiting_condition_approval
  scope :canceled
  scope :uncompleted_units_of_partially_completed_orders
  scope :ready_for_repo

  csv do
    column :id
    column :metadata_title
    column("Date Archived") {|unit| format_date(unit.date_archived)}
    column :master_files_count
  end

  config.clear_action_items!
  action_item :edit, only: :show do
     link_to "Edit", edit_resource_path  if !current_user.viewer?
  end
  action_item :pdf, :only => :show do
    raw("<a href='#{Settings.pdf_url}/#{unit.metadata.pid}?unit=#{unit.id}' target='_blank'>Download PDF</a>") if !unit.metadata.nil?
  end
  action_item :ocr, only: :show do
     link_to "OCR", "/admin/ocr?u=#{unit.id}"  if !current_user.viewer? && ocr_enabled?
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

  batch_action :print_routing_slips do |selection|

  end

  filter :id
  filter :date_archived
  filter :complete_scan
  filter :date_dl_deliverables_ready
  filter :date_queued_for_ingest
  filter :special_instructions
  filter :staff_notes
  filter :include_in_dl, :as => :select
  filter :intended_use, :as => :select
  filter :metadata_title, :as => :string, :label => "Metadata Title"
  filter :order_id, :as => :numeric, :label => "Order ID"
  filter :customer_id, :as => :numeric, :label => "Customer ID"
  filter :agency, :as => :select
  filter :indexing_scenario
  filter :master_files_count, :as => :numeric

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
    column ("In DL?") do |unit|
      format_boolean_as_yes_no(unit.include_in_dl)
    end
    column :date_archived do |unit|
      format_date(unit.date_archived)
    end
    column :date_queued_for_ingest do |unit|
      format_date(unit.date_queued_for_ingest)
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
      if !current_user.viewer?
         div do
           link_to I18n.t('active_admin.edit'), edit_resource_path(unit), :class => "member_link edit_link"
         end
         if ocr_enabled? && unit.master_files.count > 0
            div do
               link_to "OCR", "/admin/ocr?u=#{unit.id}"
            end
         end
      end
      if !unit.metadata.nil?
         div do
            link_to "PDF", "#{Settings.pdf_url}/#{unit.metadata.pid}?unit=#{unit.id}", target: "_blank"
         end
      end
    end
  end

  show :title => proc{|unit| "Unit ##{unit.id}"} do
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
          row("Date Delivered to DigiServ") do |unit|
            format_date(unit.date_materials_received)
          end
          row("Date Returned from DigiServ") do |unit|
            format_date(unit.date_materials_returned)
          end
          row :date_archived do |unit|
            format_datetime(unit.date_archived)
          end
          row :date_patron_deliverables_ready do |unit|
            format_datetime(unit.date_patron_deliverables_ready)
          end
        end
      end
    end

    div :class => "columns-none" do
      panel "Digital Library Information", :toggle => 'show' do
        attributes_table_for unit do
          row :indexing_scenario
          row ("In Digital Library?") do |unit|
            format_boolean_as_yes_no(unit.include_in_dl)
          end
          row :master_file_discoverability do |unit|
            format_boolean_as_yes_no(unit.master_file_discoverability)
          end
          row :date_queued_for_ingest do |unit|
            format_datetime(unit.date_queued_for_ingest)
          end
          row :date_dl_deliverables_ready do |unit|
            format_datetime(unit.date_dl_deliverables_ready)
          end
        end
      end
    end

    div :class => "columns-none" do
      if not unit.master_files.empty?
      then
        panel "Master Files", :toggle => 'show' do
          table_for unit.master_files do |mf|
            column :filename, :sortable => false
            column :title do |mf|
              truncate_words(mf.title)
            end
            column :description do |mf|
              truncate_words(mf.description)
            end
            column :transcription_text do |mf|
              truncate_words(raw(mf.transcription_text))
            end
            column :date_archived do |mf|
              format_date(mf.date_archived)
            end
            column :date_dl_ingest do |mf|
              format_date(mf.date_dl_ingest)
            end
            column :pid, :sortable => false
            column("Thumbnail") do |mf|
              link_to image_tag(mf.link_to_static_thumbnail, :height => 125), "#{mf.link_to_static_thumbnail(true)}", :rel => 'colorbox', :title => "#{mf.filename} (#{mf.title} #{mf.description})"
            end
            column("") do |mf|
              div do
                link_to "Details", admin_master_file_path(mf), :class => "member_link view_link"
              end
              div do
                 link_to "PDF", "#{Settings.pdf_url}/#{mf.pid}", target: "_blank"
              end
              if !current_user.viewer?
                 div do
                   link_to I18n.t('active_admin.edit'), edit_admin_master_file_path(mf), :class => "member_link edit_link"
                 end
                 if ocr_enabled?
                    div do
                       link_to "OCR", "/admin/ocr?mf=#{mf.id}"
                    end
                 end
              end
              if mf.date_archived
                div do
                  link_to "Download", copy_from_archive_admin_master_file_path(mf.id), :method => :put
                end
              end
            end
          end
        end
      else
        panel "No Master Files Directly Associated with this Component"
      end
    end
  end

  # EDIT page ================================================================
  form :partial => "edit"

  sidebar "Related Information", :only => [:show] do
    attributes_table_for unit do
      row "Metadata" do |unit|
         link_to "#{unit.metadata.title}", "/admin/#{unit.metadata.url_fragment}/#{unit.metadata.id}" if !unit.metadata.nil?
      end
      row :order do |unit|
        link_to "##{unit.order.id}", admin_order_path(unit.order.id)
      end
      row :master_files do |unit|
        link_to "#{unit.master_files_count}", admin_master_files_path(:q => {:unit_id_eq => unit.id})
      end
      row :customer
      row :agency
    end
  end

  sidebar :approval_workflow, :only => :show,  if: proc{ !current_user.viewer? } do
    div :class => 'workflow_button' do button_to "Print Routing Slip", print_routing_slip_admin_unit_path, :method => :put end

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
    if !current_user.viewer?
       if File.exist?(File.join(IN_PROCESS_DIR, "%09d" % unit.id))
            if not unit.date_archived
              div :class => 'workflow_button' do button_to "QA Unit Data", qa_unit_data_admin_unit_path , :method => :put end
              div :class => 'workflow_button' do button_to "QA Filesystem and XML", qa_filesystem_and_iview_xml_admin_unit_path , :method => :put end
              div :class => 'workflow_button' do button_to "Create Master File Records", import_unit_iview_xml_admin_unit_path, :method => :put end
              div :class => 'workflow_button' do button_to "Send Unit to Archive", send_unit_to_archive_admin_unit_path, :method => :put end
            end
            if unit.intended_use != 'Digital Collection Buidling' && !unit.date_patron_deliverables_ready
               div :class => 'workflow_button' do button_to "Generate Deliverables", check_unit_delivery_mode_admin_unit_path, :method => :put end
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
    else
      div :class => 'workflow_button' do button_to "Download Unit From Archive", copy_from_archive_admin_unit_path(unit.id), :method => :put, :disabled => true end
      div do "This unit cannot be downloaded because it is not archived." end
    end
  end

  sidebar "Digital Library Workflow", :only => [:show],  if: proc{ !current_user.viewer? && (unit.ready_for_repo? || unit.in_dl?) } do
    if unit.ready_for_repo?
      div :class => 'workflow_button' do button_to "Put into Digital Library",
         start_ingest_from_archive_admin_unit_path(:datastream => 'all'), :method => :put end
    end
    if unit.in_dl?
      div :class => 'workflow_button' do button_to "Publish",
         publish_admin_unit_path(:datastream => 'all'), :method => :put end
    end
  end

  action_item :previous, :only => :show do
    link_to("Previous", admin_unit_path(unit.previous)) unless unit.previous.nil?
  end

  action_item :next, :only => :show do
    link_to("Next", admin_unit_path(unit.next)) unless unit.next.nil?
  end

  collection_action :metadata_lookup

  member_action :print_routing_slip, :method => :put do
    @unit = Unit.find(params[:id])
    @metadata = { title: "", location: "", call_number:"" }
    if !@unit.metadata.nil?
       @metadata[:title] = @unit.metadata.title
       if @unit.metadata.type == "SirsiMetadata"
         sm = @unit.metadata.becomes(@unit.metadata.type.constantize)
         vm =  Virgo.external_lookup(sm.catalog_key, sm.barcode)
         @metadata[:call_number] = sm.call_number
         @metadata[:location] = vm[:location]
       end
    end
    @order = @unit.order
    @customer = @order.customer
    render :layout => 'printable'
  end

  # Member actions for workflow
  member_action :regenerate_deliverables, :method=>:put do
     unit = Unit.find(params[:id])
     RecreatePatronDeliverables.exec({unit: unit})
     redirect_to "/admin/units/#{params[:id]}", :notice => "Regenerating unit deliverables."
  end

  member_action :check_unit_delivery_mode, :method => :put do
    Unit.find(params[:id]).check_unit_delivery_mode
    redirect_to "/admin/units/#{params[:id]}", :notice => "Workflow started at the checking of the unit's delivery mode."
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
    Unit.find(params[:id]).start_ingest_from_archive
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit being put into digital library."
  end

  member_action :publish, :method => :put do
    unit = Unit.find(params[:id])
    now = Time.now
    unit.metadata.update_attribute(:date_dl_update, now)
    unit.master_files.each do |mf|
      mf.update_attribute(:date_dl_update, now)
    end
    logger.info "Unit #{unit.id} and #{unit.master_files.count} master files have been flagged for an update in the DL"
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit flagged for Publication"
  end

  member_action :checkout_to_digiserv, :method => :put do
    Unit.find(params[:id]).update_attribute(:date_materials_received, Time.now)
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit #{params[:id]} is now checked out to Digital Production Group."
  end

  member_action :checkin_from_digiserv, :method => :put do
    Unit.find(params[:id]).update_attribute(:date_materials_returned, Time.now)
    redirect_to "/admin/units/#{params[:id]}", :notice => "Unit #{params[:id]} has been returned from Digital Production Group."
  end

  include ActionView::Helpers::TextHelper
  controller do
     def metadata_lookup
        if params[:type] == "XmlMetadata"
           out = []
           XmlMetadata.all.order(id: :asc).each do |m|
             out << {id: m.id, title: "#{m.id}: #{m.title.truncate(50)}"}
           end
           render json: out, status: :ok
        else
           out = []
           SirsiMetadata.all.order(barcode: :asc).each do |m|
             out << {id: m.id, title: "#{m.barcode}"}
           end
           render json: out, status: :ok
        end
     end
  end
end
